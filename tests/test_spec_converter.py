"""
Test plan_to_spec() including attribute extraction.

Usage:
    uv run -m tests.test_spec_converter -d datasets/iac-eval-verified/
"""

import argparse
import json
from pathlib import Path

from src.datasets import IacEvalDataset
from src.spec_converter import plan_to_spec


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("-d", "--dataset", required=True,
                        help="Dataset directory (e.g. datasets/iac-eval-verified/)")
    parser.add_argument("-i", "--index", type=int, default=0,
                        help="Task index to test (default 0)")
    args = parser.parse_args()

    dataset = IacEvalDataset(args.dataset)
    target_dir = dataset.get_target_dir(args.index)
    print(f"Task directory: {target_dir}")

    spec = plan_to_spec(target_dir / "plan.json")
    print(json.dumps(spec, indent=2))

    # Assertions
    assert spec["resources"], "resources should not be empty"
    assert spec["attributes"], "attributes should not be empty"

    # All attribute keys must correspond to resource labels
    for label in spec["attributes"]:
        assert label in spec["resources"], (
            f"attribute label '{label}' not found in resources"
        )

    print("\nAll assertions passed.")


if __name__ == "__main__":
    main()
