"""
Edit action grammar and application for spec-based MCTS.

Edit action format (one per line):
  add(resource, aws_vpc.main)         # type.name; label auto-derived as instance name
  add(topology, sub1{main})           # label{dep_label}
  remove(resource, aws_vpc.main)      # identified by type.name; also removes topology entries
  remove(topology, sub1{main})
"""

import json
import re
import copy
from dataclasses import dataclass
from typing import Dict, List, Set

from src.spec_types import Spec


@dataclass
class EditAction:
    op: str     # "add" or "remove"
    field: str  # "resource", "topology", or "attribute"
    value: str  # e.g. "aws_vpc.main", "sub1{main}", or label for attributes
    json_value: dict = None  # JSON payload for attribute adds


def parse_edits(text: str) -> List[EditAction]:
    """
    Parse edit action strings from LLM output.

    Supports resource/topology actions and attribute actions:
      add(attribute, label, {"key": "value", ...})
      remove(attribute, label)

    Args:
        text: Raw text potentially containing edit action lines.

    Returns:
        List of EditAction objects parsed from the text.
    """
    actions = []

    # Pass 1: resource and topology actions
    pattern = r'(add|remove)\((resource|topology),\s*([^\)]+)\)'
    for match in re.finditer(pattern, text):
        op = match.group(1)
        field = match.group(2)
        value = match.group(3).strip()
        actions.append(EditAction(op=op, field=field, value=value))

    # Pass 2: remove(attribute, label) — simple regex
    for match in re.finditer(r'remove\(attribute,\s*([^\)]+)\)', text):
        label = match.group(1).strip()
        actions.append(EditAction(op="remove", field="attribute", value=label))

    # Pass 3: add(attribute, label, {json}) — brace-depth tracking
    add_attr_prefix = re.compile(r'add\(attribute,\s*([^,]+),\s*\{')
    for match in add_attr_prefix.finditer(text):
        label = match.group(1).strip()
        # Find the JSON object starting at the opening brace
        brace_start = match.end() - 1  # position of '{'
        depth = 0
        i = brace_start
        while i < len(text):
            if text[i] == '{':
                depth += 1
            elif text[i] == '}':
                depth -= 1
                if depth == 0:
                    json_str = text[brace_start:i + 1]
                    try:
                        json_value = json.loads(json_str)
                        actions.append(EditAction(
                            op="add", field="attribute",
                            value=label, json_value=json_value,
                        ))
                    except json.JSONDecodeError:
                        pass
                    break
            i += 1

    return actions


def extract_edit_dimensions(
    actions: List[EditAction],
    spec: Spec,
) -> Dict[str, Set[str]]:
    """
    Map each resource address touched by *actions* to the set of dimensions affected.

    Dimensions are ``"resource"``, ``"topology"``, and ``"attribute"``.
    For topology edits both the source and dependency labels are tagged.

    Args:
        actions: Edits to analyse.
        spec:    Parent spec used to resolve labels to full addresses.

    Returns:
        ``{address: {dim, ...}}`` keyed by full Terraform address
        (e.g. ``"aws_vpc.main"``) for every resource touched by the edits.
    """
    resources = dict(spec["resources"])
    dims: Dict[str, Set[str]] = {}

    for action in actions:
        if action.field == "resource":
            address = action.value.strip()
            label = _derive_label(address, resources)
            if action.op == "add":
                resources[label] = address
            dims.setdefault(address, set()).add("resource")

        elif action.field == "topology":
            match = re.match(r"([^{]+)\{([^}]+)\}", action.value)
            if match:
                src_label = match.group(1).strip()
                dep_label = match.group(2).strip()
                src_addr = resources.get(src_label, src_label)
                dep_addr = resources.get(dep_label, dep_label)
                dims.setdefault(src_addr, set()).add("topology")
                dims.setdefault(dep_addr, set()).add("topology")

        elif action.field == "attribute":
            label = action.value.strip()
            address = resources.get(label, label)
            dims.setdefault(address, set()).add("attribute")

    return dims


def group_edits_by_resource(
    actions: List[EditAction],
    spec: Spec,
) -> Dict[str, List[EditAction]]:
    """
    Group edit actions by the primary resource address they belong to.

    - **resource** edits: keyed by the full address in ``value``.
    - **topology** edits: keyed by the **source** label's address.
    - **attribute** edits: keyed by the label's address.

    Args:
        actions: Flat list of edit actions.
        spec:    Parent spec used to resolve labels to addresses.

    Returns:
        ``{address: [EditAction, ...]}`` preserving original action order
        within each group.
    """
    resources = dict(spec["resources"])
    groups: Dict[str, List[EditAction]] = {}

    for action in actions:
        if action.field == "resource":
            address = action.value.strip()
            label = _derive_label(address, resources)
            if action.op == "add":
                resources[label] = address
            groups.setdefault(address, []).append(action)

        elif action.field == "topology":
            match = re.match(r"([^{]+)\{([^}]+)\}", action.value)
            if match:
                src_label = match.group(1).strip()
                address = resources.get(src_label, src_label)
                groups.setdefault(address, []).append(action)

        elif action.field == "attribute":
            label = action.value.strip()
            address = resources.get(label, label)
            groups.setdefault(address, []).append(action)

    return groups


def resource_edit_combinations(
    actions: List[EditAction],
    spec: Spec,
) -> List[List[EditAction]]:
    """
    Return all non-empty combinations of resource-level edit bundles.

    First groups *actions* by resource address via
    :func:`group_edits_by_resource`, then produces every non-empty subset
    of those groups.  Each combination is a flat list of edit actions
    (the union of selected bundles).

    Args:
        actions: Flat list of edit actions.
        spec:    Parent spec used to resolve labels to addresses.

    Returns:
        2-D list where each inner list is one combination of resource bundles.
    """
    from itertools import combinations

    groups = group_edits_by_resource(actions, spec)
    bundles = list(groups.values())

    result: List[List[EditAction]] = []
    for r in range(1, len(bundles) + 1):
        for combo in combinations(bundles, r):
            merged: List[EditAction] = []
            for bundle in combo:
                merged.extend(bundle)
            result.append(merged)
    return result


def _edit_key(action: EditAction) -> tuple:
    """Return a hashable identity tuple for an EditAction."""
    jv = json.dumps(action.json_value, sort_keys=True) if action.json_value else None
    return (action.op, action.field, action.value, jv)


def match_edit_action_sets(
    actions: List[EditAction],
    action_sets: List[List[EditAction]],
) -> List[bool]:
    """
    Check which action sets contain all of the reference *actions*.

    Returns *True* for an action set if every edit in *actions* appears
    in that set (subset check, order-independent).

    Args:
        actions:     Reference list of edit actions.
        action_sets: List of edit action lists to compare against.

    Returns:
        List of booleans, one per action set.
    """
    ref = set(_edit_key(a) for a in actions)
    return [ref <= set(_edit_key(a) for a in s) for s in action_sets]


def edit_combinations(actions: List[EditAction]) -> List[List[EditAction]]:
    """
    Return all non-empty combinations of *actions*.

    Produces subsets of size 1 through len(actions), giving every possible
    bundle of edits.  Order within each combination follows the original
    list order.

    Args:
        actions: List of edit actions to combine.

    Returns:
        2-D list where each inner list is one combination.
    """
    from itertools import combinations

    result: List[List[EditAction]] = []
    for r in range(1, len(actions) + 1):
        for combo in combinations(actions, r):
            result.append(list(combo))
    return result


def apply_edits(spec: Spec, actions: List[EditAction]) -> Spec:
    """
    Apply a list of edit actions to a spec, returning a new spec (deep copy).

    Args:
        spec:    The source spec (not mutated).
        actions: List of EditAction objects to apply in order.

    Returns:
        New Spec with edits applied.
    """
    new_spec: Spec = copy.deepcopy(spec)

    for action in actions:
        if action.field == "resource":
            _apply_resource_edit(new_spec, action)
        elif action.field == "topology":
            _apply_topology_edit(new_spec, action)
        elif action.field == "attribute":
            _apply_attribute_edit(new_spec, action)

    return new_spec


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

def _derive_label(address: str, resources: dict) -> str:
    """
    Derive label from a full Terraform address, handling collisions.

    Uses the instance name (last segment) unless it is already mapped to a
    different address, in which case falls back to the full address.
    """
    parts = address.split(".")
    instance_name = parts[-1] if len(parts) >= 2 else address
    existing = resources.get(instance_name)
    if existing is not None and existing != address:
        # Collision: fall back to full address as label
        return address
    return instance_name


def _apply_resource_edit(spec: Spec, action: EditAction) -> None:
    """Mutate spec in-place: add or remove a resource."""
    address = action.value.strip()

    if action.op == "add":
        label = _derive_label(address, spec["resources"])
        spec["resources"][label] = address

    elif action.op == "remove":
        # Find the label whose value matches this address
        label_to_remove = next(
            (lbl for lbl, addr in spec["resources"].items() if addr == address),
            None,
        )
        if label_to_remove:
            del spec["resources"][label_to_remove]
            # Also remove from topology
            spec["topology"].pop(label_to_remove, None)
            for src_label in list(spec["topology"].keys()):
                spec["topology"][src_label] = [
                    d for d in spec["topology"][src_label] if d != label_to_remove
                ]


def _apply_topology_edit(spec: Spec, action: EditAction) -> None:
    """Mutate spec in-place: add or remove a topology edge."""
    match = re.match(r'([^{]+)\{([^}]+)\}', action.value)
    if not match:
        return
    src_label = match.group(1).strip()
    dep_label = match.group(2).strip()

    if action.op == "add":
        deps = spec["topology"].setdefault(src_label, [])
        if dep_label not in deps:
            deps.append(dep_label)

    elif action.op == "remove":
        if src_label in spec["topology"]:
            spec["topology"][src_label] = [
                d for d in spec["topology"][src_label] if d != dep_label
            ]


def _apply_attribute_edit(spec: Spec, action: EditAction) -> None:
    """Mutate spec in-place: add or remove an attribute entry."""
    label = action.value.strip()

    if action.op == "add" and action.json_value is not None:
        existing = spec.setdefault("attributes", {}).get(label, {})
        if existing is None:
            existing = {}
        existing.update(action.json_value)
        spec["attributes"][label] = existing

    elif action.op == "remove":
        spec.get("attributes", {}).pop(label, None)
