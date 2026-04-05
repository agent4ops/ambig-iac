"""
Test normalize_spec().

Usage:
    uv run -m tests.test_normalize_spec             # handcrafted unit test
    uv run -m tests.test_normalize_spec -d datasets/iac-eval-verified/  # real data
"""

import argparse
import json

from src.spec_converter import normalize_spec


def test_handcrafted():
    """Test with a handcrafted spec containing multiple resources of the same type."""
    spec = {
        "resources": {
            "web": "aws_instance.web",
            "api": "aws_instance.api",
            "main": "aws_vpc.main",
            "pub": "aws_subnet.pub",
            "priv": "aws_subnet.priv",
            "policy": "data.aws_iam_policy_document.policy",
        },
        "topology": {
            "pub": ["main"],
            "priv": ["main"],
            "web": ["pub"],
            "api": ["priv"],
        },
        "attributes": {
            "main": {"cidr_block": "10.0.0.0/16"},
            "web": {"instance_type": "t2.micro"},
        },
    }

    normalized, label_map = normalize_spec(spec)

    print("=== Original ===")
    print(json.dumps(spec, indent=2))
    print("\n=== Normalized ===")
    print(json.dumps(normalized, indent=2))
    print("\n=== Label Map ===")
    print(json.dumps(label_map, indent=2))

    # Check that types are grouped and indexed
    instance_labels = [l for l in normalized["resources"] if l.startswith("aws_instance_")]
    subnet_labels = [l for l in normalized["resources"] if l.startswith("aws_subnet_")]
    vpc_labels = [l for l in normalized["resources"] if l.startswith("aws_vpc_")]
    data_labels = [l for l in normalized["resources"]
                   if l.startswith("aws_iam_policy_document_")]

    assert len(instance_labels) == 2, f"Expected 2 instance labels, got {instance_labels}"
    assert len(subnet_labels) == 2, f"Expected 2 subnet labels, got {subnet_labels}"
    assert len(vpc_labels) == 1, f"Expected 1 vpc label, got {vpc_labels}"
    assert len(data_labels) == 1, f"Expected 1 data label, got {data_labels}"

    # Topology should be remapped
    assert all(l in normalized["resources"] for deps in normalized["topology"].values()
               for l in deps), "All topology deps must exist in resources"

    # Attributes should be remapped
    for label in normalized["attributes"]:
        assert label in normalized["resources"], (
            f"attribute label '{label}' not found in normalized resources"
        )

    print("\nAll handcrafted assertions passed.")


def test_real_data(dataset_dir: str, index: int = 0):
    """Test with real dataset data."""
    from pathlib import Path
    from src.datasets import IacEvalDataset
    from src.spec_converter import plan_to_spec

    dataset = IacEvalDataset(dataset_dir)
    target_dir = dataset.get_target_dir(index)
    spec = plan_to_spec(target_dir / "plan.json")

    normalized, label_map = normalize_spec(spec)

    print(f"\n=== Task {index} Original ===")
    print(json.dumps(spec, indent=2))
    print(f"\n=== Task {index} Normalized ===")
    print(json.dumps(normalized, indent=2))
    print(f"\n=== Label Map ===")
    print(json.dumps(label_map, indent=2))

    # All normalized resource labels should appear in normalized topology/attributes
    for label in normalized["attributes"]:
        assert label in normalized["resources"]

    print(f"\nReal data test (task {index}) passed.")


def test_plan_to_spec_normalize(dataset_dir: str, index: int = 0):
    """
    End-to-end: load plan.json → plan_to_spec → normalize_spec.

    Validates structural invariants that must hold after normalization:
      - resource count preserved
      - topology edge count preserved
      - attribute count preserved
      - all topology labels exist in resources
      - all attribute labels exist in resources
      - no label collisions (each new label is unique)
      - label format is {aws_type}_{index}
    """
    import re
    from pathlib import Path
    from src.datasets import IacEvalDataset
    from src.spec_converter import plan_to_spec

    dataset = IacEvalDataset(dataset_dir)
    target_dir = dataset.get_target_dir(index)
    spec = plan_to_spec(target_dir / "plan.json")
    normalized, label_map = normalize_spec(spec)

    print(f"\n=== Plan→Spec→Normalize (task {index}) ===")
    print(f"Resources: {len(spec['resources'])} → {len(normalized['resources'])}")
    print(f"Topology entries: {len(spec['topology'])} → {len(normalized['topology'])}")
    print(f"Attributes: {len(spec.get('attributes', {}))} → {len(normalized.get('attributes', {}))}")

    # 1. Resource count preserved
    assert len(normalized["resources"]) == len(spec["resources"]), (
        f"Resource count changed: {len(spec['resources'])} → {len(normalized['resources'])}"
    )

    # 2. Topology edge count preserved
    orig_edges = sum(len(deps) for deps in spec["topology"].values())
    norm_edges = sum(len(deps) for deps in normalized["topology"].values())
    assert norm_edges == orig_edges, (
        f"Topology edge count changed: {orig_edges} → {norm_edges}"
    )

    # 3. Attribute count preserved
    assert len(normalized.get("attributes", {})) == len(spec.get("attributes", {})), (
        f"Attribute count changed"
    )

    # 4. All topology labels exist in resources
    all_labels = set(normalized["resources"].keys())
    for src, deps in normalized["topology"].items():
        assert src in all_labels, f"Topology src '{src}' not in resources"
        for dep in deps:
            assert dep in all_labels, f"Topology dep '{dep}' not in resources"

    # 5. All attribute labels exist in resources
    for label in normalized.get("attributes", {}):
        assert label in all_labels, f"Attribute label '{label}' not in resources"

    # 6. No label collisions — label_map values are all unique
    new_labels = list(label_map.values())
    assert len(new_labels) == len(set(new_labels)), (
        f"Label map has duplicates: {new_labels}"
    )

    # 7. Label format: {type}_{digit}
    for new_label in normalized["resources"]:
        assert re.match(r'^.+_\d+$', new_label), (
            f"Label '{new_label}' doesn't match expected format '<type>_<index>'"
        )

    # 8. label_map covers every original label
    assert set(label_map.keys()) == set(spec["resources"].keys()), (
        "label_map keys don't match original resource labels"
    )

    print(json.dumps(normalized, indent=2))
    print(f"\nPlan→Spec→Normalize test (task {index}) passed.")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("-d", "--dataset", default=None,
                        help="Dataset directory for real data test")
    parser.add_argument("-i", "--index", type=int, default=0)
    args = parser.parse_args()

    test_handcrafted()

    if args.dataset:
        test_real_data(args.dataset, args.index)
        test_plan_to_spec_normalize(args.dataset, args.index)


if __name__ == "__main__":
    main()
