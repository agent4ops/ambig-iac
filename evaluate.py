"""
Spec evaluation v2: GED-based structure scoring + embedding-based attribute scoring.

Replaces the coarse type-count matching with:
  - Graph Edit Distance (GED) for combined resource + topology evaluation
  - Local embedding cosine similarity for per-node attribute comparison

Usage:
    uv run evaluate_v2.py --dataset iac-eval --target results/self_consistency/
    uv run evaluate_v2.py --dataset iac-eval --target results/self_consistency/ --task_id 0
"""

import argparse
import json
from pathlib import Path

import networkx as nx
import numpy as np

from src.datasets import IacEvalDataset, MultiIacUpdatesDataset, MultiIacProvisionDataset
from src.spec_converter import plan_to_spec, normalize_spec

# ---------------------------------------------------------------------------
# Lazy-loaded embedding model
# ---------------------------------------------------------------------------

_embed_model = None


def _get_embed_model():
    global _embed_model
    if _embed_model is None:
        from sentence_transformers import SentenceTransformer
        _embed_model = SentenceTransformer("all-MiniLM-L6-v2")
    return _embed_model


# ---------------------------------------------------------------------------
# Graph construction
# ---------------------------------------------------------------------------


def _resource_type(address: str) -> str:
    """Extract the resource type from a Terraform address."""
    parts = address.split(".")
    if len(parts) >= 3 and parts[0] == "data":
        return f"{parts[0]}.{parts[1]}"
    return parts[0]


def spec_to_digraph(spec: dict) -> nx.DiGraph:
    """Build a labeled directed graph from a spec.

    Nodes carry a ``type`` attribute (e.g. ``aws_vpc``).
    Edges represent topology dependencies (src depends on dep).
    """
    g = nx.DiGraph()
    for label, address in spec.get("resources", {}).items():
        g.add_node(label, type=_resource_type(address))
    for src_label, dep_labels in spec.get("topology", {}).items():
        for dep_label in dep_labels:
            if src_label in g and dep_label in g:
                g.add_edge(src_label, dep_label)
    return g


# ---------------------------------------------------------------------------
# GED computation with node mapping
# ---------------------------------------------------------------------------


def _node_subst_cost(n1_attrs: dict, n2_attrs: dict) -> float:
    """Cost of substituting one node for another. 0 if same type, 1 otherwise."""
    return 0.0 if n1_attrs.get("type") == n2_attrs.get("type") else 1.0


def _node_del_cost(n_attrs: dict) -> float:
    return 1.0


def _node_ins_cost(n_attrs: dict) -> float:
    return 1.0


def _edge_subst_cost(e1_attrs: dict, e2_attrs: dict) -> float:
    return 0.0  # edges have no attributes; matched edge = free


def _edge_del_cost(e_attrs: dict) -> float:
    return 1.0


def _edge_ins_cost(e_attrs: dict) -> float:
    return 1.0


def compute_ged(g_ref: nx.DiGraph, g_gen: nx.DiGraph, timeout: float = 30.0):
    """Compute GED between two graphs and return (score, ged, node_mapping).

    ``score`` is normalized to [0, 1] where 1.0 = identical graphs.
    ``node_mapping`` maps ref_label -> gen_label (or None for deletions).

    Uses ``optimize_edit_paths`` which yields progressively better solutions.
    We take the best within *timeout* seconds.
    """
    import time

    n_ref = g_ref.number_of_nodes() + g_ref.number_of_edges()
    n_gen = g_gen.number_of_nodes() + g_gen.number_of_edges()
    max_possible = n_ref + n_gen

    # Both empty -> perfect match
    if max_possible == 0:
        return 1.0, 0.0, {}, []

    upper_bound = max_possible  # worst case: delete all ref, insert all gen

    best_cost = upper_bound
    best_node_path = []

    start = time.time()
    try:
        for node_path, _edge_path, cost in nx.optimize_edit_paths(
            g_ref,
            g_gen,
            node_subst_cost=_node_subst_cost,
            node_del_cost=_node_del_cost,
            node_ins_cost=_node_ins_cost,
            edge_subst_cost=_edge_subst_cost,
            edge_del_cost=_edge_del_cost,
            edge_ins_cost=_edge_ins_cost,
            upper_bound=upper_bound,
            timeout=timeout,
        ):
            if cost < best_cost:
                best_cost = cost
                best_node_path = list(node_path)
            # can be removed. This is a fallback. timeout should be reached in the networkx function.
            if time.time() - start > timeout:
                break
    except Exception:
        # Fallback: treat as maximum distance
        return 0.0, float(max_possible), {}, []

    # Build node mapping: ref_label -> gen_label (None = deleted/unmatched)
    mapping = {}
    extra_gen_nodes = []
    for u, v in best_node_path:
        if u is not None:
            mapping[u] = v  # v may be None (ref node deleted)
        elif v is not None:
            extra_gen_nodes.append(v)  # gen node with no ref counterpart

    score = max(0.0, 1.0 - best_cost / max_possible)
    return round(score, 4), round(best_cost, 2), mapping, extra_gen_nodes


# ---------------------------------------------------------------------------
# Attribute similarity via local embeddings
# ---------------------------------------------------------------------------


def _serialize_attributes(label: str, spec: dict) -> str:
    """Canonical string representation of a node's resource type + attributes."""
    address = spec.get("resources", {}).get(label, label)
    rtype = _resource_type(address)
    attrs = spec.get("attributes", {}).get(label, {})
    # Sort keys for determinism
    parts = [f"type={rtype}"]
    for k in sorted(attrs.keys()):
        parts.append(f"{k}={attrs[k]}")
    return ", ".join(parts)


def _cosine_similarity(a: np.ndarray, b: np.ndarray) -> float:
    norm = np.linalg.norm(a) * np.linalg.norm(b)
    if norm == 0:
        return 0.0
    return float(np.dot(a, b) / norm)


def compute_attribute_similarity(
    mapping: dict, extra_gen_nodes: list, ref_spec: dict, gen_spec: dict
) -> tuple[float, dict]:
    """Compute per-node attribute similarity for aligned node pairs.

    Penalizes both missing ref nodes (mapped to None) and extra gen nodes
    (present in generated but not in reference) with a score of 0.

    Args:
        mapping: ref_label -> gen_label (from GED). None values = unmatched.
        extra_gen_nodes: gen labels with no ref counterpart (insertions).
        ref_spec: reference spec (normalized).
        gen_spec: generated spec (normalized).

    Returns:
        (overall_score, per_node_scores) where per_node_scores maps
        label -> similarity float (ref labels for matches/deletions,
        gen labels prefixed with '+' for extras).
    """
    if not mapping and not extra_gen_nodes:
        ref_has_nodes = bool(ref_spec.get("resources"))
        gen_has_nodes = bool(gen_spec.get("resources"))
        if not ref_has_nodes and not gen_has_nodes:
            return 1.0, {}
        return 0.0, {}

    # Collect all texts to embed in one batch
    ref_texts = []
    gen_texts = []
    matched_pairs = []  # ref_labels that need embedding

    per_node: dict[str, float] = {}

    for ref_label, gen_label in mapping.items():
        if gen_label is None:
            per_node[ref_label] = 0.0
            continue

        ref_attrs = ref_spec.get("attributes", {}).get(ref_label, {})
        gen_attrs = gen_spec.get("attributes", {}).get(gen_label, {})

        # Both empty -> perfect attribute match for this node
        if not ref_attrs and not gen_attrs:
            per_node[ref_label] = 1.0
            continue

        ref_texts.append(_serialize_attributes(ref_label, ref_spec))
        gen_texts.append(_serialize_attributes(gen_label, gen_spec))
        matched_pairs.append(ref_label)

    # Penalize extra gen nodes (insertions) — no ref counterpart
    for gen_label in extra_gen_nodes:
        per_node[f"+{gen_label}"] = 0.0

    # Embed and score
    if matched_pairs:
        model = _get_embed_model()
        all_texts = ref_texts + gen_texts
        embeddings = model.encode(all_texts, normalize_embeddings=True)
        n = len(ref_texts)
        for i, ref_label in enumerate(matched_pairs):
            sim = _cosine_similarity(embeddings[i], embeddings[n + i])
            per_node[ref_label] = round(max(0.0, sim), 4)

    # Average across all nodes (ref matched/deleted + extra gen)
    if per_node:
        overall = sum(per_node.values()) / len(per_node)
    else:
        overall = 1.0

    return round(overall, 4), per_node


# ---------------------------------------------------------------------------
# Task evaluation
# ---------------------------------------------------------------------------


def evaluate_task(task_id: int, target_dir: Path, dataset_target_dir: Path) -> dict:
    """Evaluate a single task: GED structure score + embedding attribute score."""
    spec_path = target_dir / str(task_id) / "spec.json"
    if not spec_path.exists():
        return {"error": f"spec.json not found at {spec_path}"}

    gen_spec = json.loads(spec_path.read_text())
    ref_spec = plan_to_spec(dataset_target_dir / "plan.json")

    # Normalize both specs for comparable labels
    norm_gen, _ = normalize_spec(gen_spec)
    norm_ref, _ = normalize_spec(ref_spec)

    # Structure: GED on resource+topology graphs
    g_ref = spec_to_digraph(norm_ref)
    g_gen = spec_to_digraph(norm_gen)
    structure_score, ged, node_mapping, extra_gen_nodes = compute_ged(g_ref, g_gen)

    # Attributes: embedding similarity on aligned nodes
    attr_score, per_node_attrs = compute_attribute_similarity(
        node_mapping, extra_gen_nodes, norm_ref, norm_gen
    )

    return {
        "structure": {
            "score": structure_score,
            "ged": ged,
            "node_mapping": {k: v for k, v in node_mapping.items()},
        },
        "attributes": {
            "score": attr_score,
            "per_node": per_node_attrs,
        },
    }


# ---------------------------------------------------------------------------
# CLI — same interface as evaluate.py
# ---------------------------------------------------------------------------


def main():
    parser = argparse.ArgumentParser(
        description="Evaluate generated specs against ground-truth (v2: GED + embeddings)."
    )
    parser.add_argument("--dataset", required=True,
                        help="Dataset to use. Choices: iac-eval, ambig-iac, multi-iac-updates, multi-iac-provision.")
    parser.add_argument("--target", required=True,
                        help="Path to results directory with task subdirs containing spec.json")
    parser.add_argument("--task_id", type=int, default=None,
                        help="Evaluate a single task by ID")
    parser.add_argument("--config", type=str, default=None,
                        help="Path to config JSON (unused in v2, kept for interface compatibility)")
    parser.add_argument("--continue", action="store_true", dest="continue_run",
                        help="Skip tasks that already have eval_v2.json.")
    parser.add_argument("--dataset_rev", action="store_true",
                        help="Loop through the dataset in reverse order.")
    args = parser.parse_args()

    # Dataset loading (mirrors evaluate.py)
    if args.dataset == "ambig-iac":
        root_dir = "datasets/ambig-iac/"
        dataset = IacEvalDataset(dataset_root=root_dir)
    elif "iac-eval" in args.dataset:
        root_dir = "datasets/iac-eval-verified/"
        dataset = IacEvalDataset(dataset_root=root_dir)
    elif "multi-iac-updates" in args.dataset:
        root_dir = "datasets/multi-iac-updates/"
        dataset = MultiIacUpdatesDataset(dataset_root=root_dir)
    elif "multi-iac-provision" in args.dataset:
        root_dir = "datasets/multi-iac-provision/"
        dataset = MultiIacProvisionDataset(dataset_root=root_dir)
    else:
        raise ValueError(f"Invalid dataset: {args.dataset}")

    target = Path(args.target)

    if args.task_id is not None:
        task_ids = [args.task_id]
    else:
        task_ids = []
        for i in range(len(dataset)):
            if (target / str(i) / "spec.json").exists():
                task_ids.append(i)

    if args.dataset_rev:
        task_ids = list(reversed(task_ids))

    print(f"Evaluating {len(task_ids)} tasks (v2: GED + embeddings)...")

    scores = {"structure": [], "attributes": []}

    for task_id in task_ids:
        eval_file = target / str(task_id) / "eval_v2.json"

        if args.continue_run and eval_file.exists():
            existing = json.loads(eval_file.read_text())
            if "error" not in existing:
                for axis in scores:
                    scores[axis].append(existing[axis]["score"])
            print(f"  Task {task_id}: already evaluated, skipping.")
            continue

        dataset_target_dir = dataset.get_target_dir(task_id)
        result = evaluate_task(task_id, target, dataset_target_dir)

        # Write eval_v2.json
        out_dir = target / str(task_id)
        out_dir.mkdir(parents=True, exist_ok=True)
        eval_file.write_text(json.dumps(result, indent=2))

        if "error" in result:
            print(f"  Task {task_id}: ERROR - {result['error']}")
            continue

        for axis in scores:
            scores[axis].append(result[axis]["score"])

        print(
            f"  Task {task_id}: "
            f"structure={result['structure']['score']:.2f} (ged={result['structure']['ged']})  "
            f"attributes={result['attributes']['score']:.2f}"
        )

    # Summary
    print("\n--- Summary ---")
    for axis in scores:
        vals = scores[axis]
        if vals:
            avg = sum(vals) / len(vals)
            print(f"  {axis:12s}: avg={avg:.4f}  n={len(vals)}")
        else:
            print(f"  {axis:12s}: no results")


if __name__ == "__main__":
    main()
