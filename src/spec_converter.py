"""
Conversion utilities between Terraform plan.json and the compact Spec format.
"""

import json
from collections import Counter
from pathlib import Path
from typing import Dict, List

from src.utils.build_deps import (
    build_graph_from_plan_json_file,
    extract_topo,
    extract_attributes,
)
from src.spec_types import Spec


# Module-level cache: resolved plan path -> Spec
_spec_cache: Dict[str, Spec] = {}


def plan_to_spec(plan_json_path: Path) -> Spec:
    """
    Load and convert a Terraform plan JSON file into a compact Spec dict.

    Label derivation: label = instance name part of the Terraform address.
    e.g. "aws_vpc.main" -> label "main".
    Collision handling: if two resources share the same instance name across
    different types, the full address "type.name" is used as the label.

    Results are cached by resolved plan path to avoid re-parsing the same plan.

    Args:
        plan_json_path: Path to the plan JSON file to convert.

    Returns:
        Spec with resources, topology, and empty attributes.
    """
    plan_json_path = Path(plan_json_path)
    cache_key = str(plan_json_path.resolve())
    if cache_key in _spec_cache:
        return _spec_cache[cache_key]

    g = build_graph_from_plan_json_file(plan_json_path)

    raw_topo = extract_topo(g)  # {"type.name": ["dep_type.name", ...]}

    # Build flat list of (full_address, instance_name) pairs directly from
    # graph nodes so that data resources keep their 3-part addresses
    # (e.g. "data.aws_iam_policy_document.route53-..." instead of truncated
    # "data.aws_iam_policy_document" that extract_resources would produce).
    all_pairs: List[tuple] = []
    for node in g.nodes():
        parts = node.split(".")
        # Last segment is always the instance name for both managed and data resources
        instance_name = parts[-1] if len(parts) >= 2 else node
        all_pairs.append((node, instance_name))

    # Detect label collisions: same instance name used by multiple resource types
    name_counter = Counter(name for _, name in all_pairs)

    # Build resources dict: label -> "type.name"
    resources: Dict[str, str] = {}
    for address, name in all_pairs:
        if name_counter[name] > 1:
            # Collision: use full address as label
            resources[address] = address
        else:
            resources[name] = address

    # Build reverse map: full address -> label (for topology remapping)
    addr_to_label: Dict[str, str] = {addr: label for label, addr in resources.items()}

    # Remap topology from full addresses to labels
    topology: Dict[str, List[str]] = {}
    for src_addr, dep_addrs in raw_topo.items():
        src_label = addr_to_label.get(src_addr, src_addr)
        dep_labels = [addr_to_label.get(dep, dep) for dep in dep_addrs]
        topology[src_label] = dep_labels

    # Extract and remap attributes from full addresses to labels
    raw_attrs = extract_attributes(g)
    attributes: Dict[str, dict] = {}
    for addr, attr_dict in raw_attrs.items():
        if attr_dict:
            label = addr_to_label.get(addr, addr)
            attributes[label] = attr_dict

    spec: Spec = {
        "resources": resources,
        "topology": topology,
        "attributes": attributes,
    }

    _spec_cache[cache_key] = spec
    return spec


def normalize_spec(spec: Spec) -> tuple:
    """
    Normalize a spec by assigning sequential, deterministic labels per resource type.

    This makes two specs comparable even when they use different instance names
    for the same resource types.

    Label format: ``{full_aws_type}_{index}`` (e.g. ``aws_vpc_0``, ``aws_subnet_0``).
    Address format: ``{type}.{new_label}``; for data resources: ``data.{type}.{new_label}``.

    Args:
        spec: The spec to normalize.

    Returns:
        (normalized_spec, label_map) where label_map = {old_label: new_label}.
    """
    from collections import defaultdict

    # Group labels by resource type extracted from the address
    type_groups: Dict[str, List[str]] = defaultdict(list)
    for label, address in spec["resources"].items():
        parts = address.split(".")
        if parts[0] == "data" and len(parts) >= 3:
            rtype = f"{parts[0]}.{parts[1]}"
        elif len(parts) >= 2:
            rtype = parts[0]
        else:
            rtype = address
        type_groups[rtype].append(label)

    # Sort labels within each type group for determinism
    for rtype in type_groups:
        type_groups[rtype].sort()

    # Build label_map: old_label -> new_label
    label_map: Dict[str, str] = {}
    new_resources: Dict[str, str] = {}
    for rtype, labels in sorted(type_groups.items()):
        # Extract the AWS type portion (without "data." prefix for naming)
        if rtype.startswith("data."):
            aws_type = rtype[5:]  # e.g. "aws_iam_policy_document"
        else:
            aws_type = rtype
        for idx, old_label in enumerate(labels):
            new_label = f"{aws_type}_{idx}"
            label_map[old_label] = new_label
            # Build new address
            old_address = spec["resources"][old_label]
            parts = old_address.split(".")
            if parts[0] == "data":
                new_address = f"data.{aws_type}.{new_label}"
            else:
                new_address = f"{aws_type}.{new_label}"
            new_resources[new_label] = new_address

    # Remap topology
    new_topology: Dict[str, List[str]] = {}
    for src_label, dep_labels in spec["topology"].items():
        new_src = label_map.get(src_label, src_label)
        new_deps = [label_map.get(d, d) for d in dep_labels]
        new_topology[new_src] = new_deps

    # Remap attributes
    new_attributes: Dict[str, dict] = {}
    for label, attrs in spec.get("attributes", {}).items():
        new_label = label_map.get(label, label)
        new_attributes[new_label] = attrs

    normalized: Spec = {
        "resources": new_resources,
        "topology": new_topology,
        "attributes": new_attributes,
    }
    return normalized, label_map

