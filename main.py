"""
Main script to run the interactive IaC generation with the user proxy.

Example usage:
```
uv run main.py --dataset ambig-iac --task_id 0 --max_questions 5 --method direct_random_q --out_dir results/
uv run main.py --dataset ambig-iac --max_questions 10 --method dimension_aware_refinement --out_dir results/ours/
```

Methods
-------
direct              No clarification — passes prompt through as-is.
direct_random_q     LLM generates random yes/no questions; UserProxy answers them.
best_of_n           Iteratively generate, rank, and ask the best clarification question each round.
self_consistency    Generate many candidate questions, cluster by embedding similarity, ask the consensus question.
dimension_aware_refinement  Generate candidate specs, compute structural disagreements across resource/topology/attribute axes, rank by entropy with round-robin balancing, and ask targeted clarification questions.
"""

import argparse
import json
import time
from pathlib import Path

from src.config import load_config
from src.datasets import (
    BaseDataset,
    IacEvalDataset,
    MultiIacProvisionDataset,
    MultiIacUpdatesDataset,
)
from src.methods import build_method
from src.spec_generator import SpecGenerator
from src.spec_types import is_empty_spec, is_valid_spec
from src.utils.utils import is_awscc

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _merge_usage(target: dict, source: dict) -> None:
    """Sum token-count fields from *source* into *target* in place."""
    for key in ("completion_tokens", "prompt_tokens", "total_tokens", "cached_tokens"):
        target[key] = target.get(key, 0) + source.get(key, 0)


def _task_complete(out_dir: str, task_id: int) -> bool:
    """Return True if all expected outputs exist for this task."""
    d = Path(out_dir) / str(task_id)
    return all(
        (d / f).exists()
        for f in ("clarified_intent.txt", "spec.json", "spec_generator_llm_memory.json")
    )


def _redact_keys(config: dict) -> dict:
    """Return a copy of config with api_key values redacted."""
    redacted = {}
    for role, role_cfg in config.items():
        if isinstance(role_cfg, dict):
            redacted[role] = {
                k: ("***" if "key" in k.lower() else v) for k, v in role_cfg.items()
            }
        else:
            redacted[role] = role_cfg
    return redacted


def _parse_spec(raw_spec: str) -> dict:
    """Parse a raw spec string into a dict with guaranteed keys."""
    try:
        spec = json.loads(raw_spec)
        spec.setdefault("resources", {})
        spec.setdefault("topology", {})
        spec.setdefault("attributes", {})
    except (json.JSONDecodeError, ValueError):
        spec = {"resources": {}, "topology": {}, "attributes": {}}
    return spec


def run_task(
    task_id: int,
    dataset: BaseDataset,
    method_fn,
    out_dir: str,
    config: dict = None,
    method_name: str = "",
    method_kwargs: dict = None,
):
    """Run a single task: method -> spec generation -> save outputs."""
    start_time = time.time()
    prompt = dataset[task_id]
    cfg = dataset.tasks_dict_list[task_id]["main"].read_text().strip()

    awscc = is_awscc(prompt)
    print(f"[Task {task_id}] AWSCC: {awscc} Prompt: {prompt}\n")

    # 1. Method produces clarified intent
    result = method_fn(prompt, cfg)
    clarified_intent = result["clarified_intent"]
    print(f"[Clarified Intent]\n{clarified_intent}\n")

    # 2. Generate spec from clarified intent unless the method already selected one
    spec_gen_trace = None
    if (result.get("spec") is not None) and is_valid_spec(result["spec"]) and not is_empty_spec(result["spec"]):
        spec = result["spec"]
    else:
        spec_gen = SpecGenerator(config=config, awscc=awscc)
        spec = _parse_spec(spec_gen.generate_spec(prompt, feedback=clarified_intent))
        spec_gen_trace = {
            "messages": spec_gen.llm.get_memory(),
            "usage": spec_gen.llm.get_usage(),
            "config": spec_gen.llm.get_config(),
        }

    # 3. Save outputs
    out = Path(out_dir) / str(task_id)
    out.mkdir(parents=True, exist_ok=True)
    (out / "clarified_intent.txt").write_text(clarified_intent)
    (out / "spec.json").write_text(json.dumps(spec, indent=2))
    for name, trace in result["traces"].items():
        (out / f"{name}_memory.json").write_text(json.dumps(trace, indent=2))
    if spec_gen_trace is not None:
        (out / "spec_generator_llm_memory.json").write_text(
            json.dumps(spec_gen_trace, indent=2)
        )

    # 4. Aggregate token usage and save stats
    total_usage = {}
    for trace in result["traces"].values():
        if "usage" in trace:
            _merge_usage(total_usage, trace["usage"])
    if spec_gen_trace is not None:
        _merge_usage(total_usage, spec_gen_trace["usage"])
    stats = {
        "total_usage": total_usage,
        "runtime_seconds": round(time.time() - start_time, 2),
        "method": method_name,
        "method_settings": method_kwargs or {},
    }
    (out / "stats.json").write_text(json.dumps(stats, indent=2))

    print(f"[Output] Saved to {out}/")
    print(f"  - clarified_intent.txt ({len(clarified_intent)} chars)")
    print(f"  - spec.json ({len(spec['resources'])} resources)")
    for name, trace in result["traces"].items():
        if "messages" in trace:
            print(
                f"  - {name}_memory.json ({len(trace['messages'])} messages, {trace['usage'].get('total_tokens', 0)} tokens)"
            )
        else:
            print(f"  - {name}_memory.json")
    if spec_gen_trace is not None:
        print(
            f"  - spec_generator_llm_memory.json ({len(spec_gen_trace['messages'])} messages, {spec_gen_trace['usage'].get('total_tokens', 0)} tokens)"
        )


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def parse_args():
    parser = argparse.ArgumentParser(
        description="Interactive IaC generation with a user proxy.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Examples:\n"
            "  uv run main.py --dataset ambig-iac --task_id 0 --max_questions 5 --method direct_random_q --out_dir results/\n"
            "  uv run main.py --dataset ambig-iac --method best_of_n --max_questions 10 --n_candidates 3 --out_dir results/best_of_n/\n"
            "  uv run main.py --dataset ambig-iac --method dimension_aware_refinement --max_questions 10 --out_dir results/ours/"
        ),
    )
    parser.add_argument(
        "--dataset",
        type=str,
        required=True,
        choices=["ambig-iac", "multi-iac-updates", "multi-iac-provision"],
        help="Dataset to use.",
    )
    parser.add_argument(
        "--task_id",
        type=int,
        default=None,
        help="Task ID to run. Omit to run all tasks.",
    )
    parser.add_argument("--max_questions", type=int, required=True)
    parser.add_argument(
        "--method",
        type=str,
        required=True,
        choices=[
            "direct",
            "direct_random_q",
            "best_of_n",
            "self_consistency",
            "dimension_aware_refinement",
        ],
        help="Clarification method to use.",
    )
    parser.add_argument(
        "--n_candidates",
        type=int,
        default=None,
        help="Number of candidate questions per round (best_of_n / self_consistency).",
    )
    parser.add_argument("--out_dir", type=str, required=True)
    parser.add_argument(
        "--config",
        type=str,
        default=None,
        help="Path to JSON config file with per-role LLM settings.",
    )
    parser.add_argument(
        "--continue",
        action="store_true",
        dest="continue_run",
        help="Skip already-completed tasks.",
    )
    parser.add_argument(
        "--dataset_rev",
        action="store_true",
        help="Loop through the dataset in reverse order.",
    )
    return parser.parse_args()


def main():
    args = parse_args()

    config = load_config(args.config)

    # dataset roots
    if args.dataset == "ambig-iac":
        root_dir = "datasets/ambig-iac/"
        dataset = IacEvalDataset(dataset_root=root_dir)
    elif "multi-iac-updates" in args.dataset:
        root_dir = "datasets/multi-iac-updates/"
        dataset = MultiIacUpdatesDataset(dataset_root=root_dir)
    elif "multi-iac-provision" in args.dataset:
        root_dir = "datasets/multi-iac-provision/"
        dataset = MultiIacProvisionDataset(dataset_root=root_dir)
    else:
        raise ValueError(f"Invalid dataset: {args.dataset}")

    method_kwargs = {"max_questions": args.max_questions}

    if args.method in ("best_of_n", "self_consistency"):
        if args.n_candidates is None:
            raise ValueError(f"Method '{args.method}' requires: --n_candidates")
        method_kwargs["n_candidates"] = args.n_candidates

    method_fn = build_method(args.method, config=config, **method_kwargs)

    # Save config for reproducibility (redact API keys)
    out_root = Path(args.out_dir)
    out_root.mkdir(parents=True, exist_ok=True)
    safe_config = _redact_keys(config)
    (out_root / "config.json").write_text(json.dumps(safe_config, indent=2))

    task_ids = [args.task_id] if args.task_id is not None else range(len(dataset))
    if args.dataset_rev:
        task_ids = list(reversed(task_ids))
    for tid in task_ids:
        if args.continue_run and _task_complete(args.out_dir, tid):
            print(f"[Task {tid}] Already complete, skipping.")
            continue
        try:
            run_task(
                tid,
                dataset,
                method_fn,
                args.out_dir,
                config=config,
                method_name=args.method,
                method_kwargs=method_kwargs,
            )
        except Exception as e:
            print(f"[Task {tid}] FAILED: {e}")


if __name__ == "__main__":
    main()
