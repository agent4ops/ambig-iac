"""
Test attribute edit actions (parse_edits + apply_edits).

Usage:
    uv run -m tests.test_edit_actions           # unit tests only
    uv run -m tests.test_edit_actions --live     # include LLM integration test
"""

import argparse
import json

from src.edit_actions import parse_edits, apply_edits, EditAction


def test_parse_attribute_add():
    """Test parsing add(attribute, ...) with JSON payload."""
    text = 'add(attribute, main, {"cidr_block": "10.0.0.0/16", "enable_dns": true})'
    actions = parse_edits(text)
    attr_actions = [a for a in actions if a.field == "attribute"]
    assert len(attr_actions) == 1
    a = attr_actions[0]
    assert a.op == "add"
    assert a.value == "main"
    assert a.json_value == {"cidr_block": "10.0.0.0/16", "enable_dns": True}
    print("  parse add(attribute) ... OK")


def test_parse_attribute_remove():
    """Test parsing remove(attribute, label)."""
    text = "remove(attribute, web)"
    actions = parse_edits(text)
    attr_actions = [a for a in actions if a.field == "attribute"]
    assert len(attr_actions) == 1
    a = attr_actions[0]
    assert a.op == "remove"
    assert a.value == "web"
    assert a.json_value is None
    print("  parse remove(attribute) ... OK")


def test_parse_mixed():
    """Test parsing a mix of resource, topology, and attribute actions."""
    text = (
        "### Option 1 ###\n"
        "add(resource, aws_vpc.main)\n"
        "add(topology, sub1{main})\n"
        'add(attribute, main, {"cidr_block": "10.0.0.0/16"})\n'
        "remove(attribute, old_label)\n"
    )
    actions = parse_edits(text)
    assert len(actions) == 4, f"Expected 4 actions, got {len(actions)}"
    fields = [a.field for a in actions]
    assert fields.count("resource") == 1
    assert fields.count("topology") == 1
    assert fields.count("attribute") == 2
    print("  parse mixed actions ... OK")


def test_parse_nested_json():
    """Test parsing attribute add with nested JSON."""
    text = 'add(attribute, elb, {"listener": {"instance_port": 80, "lb_port": 80}, "health_check": {"target": "HTTP:80/"}})'
    actions = parse_edits(text)
    attr_actions = [a for a in actions if a.field == "attribute"]
    assert len(attr_actions) == 1
    assert "listener" in attr_actions[0].json_value
    assert attr_actions[0].json_value["listener"]["instance_port"] == 80
    print("  parse nested JSON attribute ... OK")


def test_apply_attribute_add():
    """Test applying an attribute add action."""
    spec = {
        "resources": {"main": "aws_vpc.main"},
        "topology": {},
        "attributes": {},
    }
    actions = [EditAction(op="add", field="attribute", value="main",
                          json_value={"cidr_block": "10.0.0.0/16"})]
    result = apply_edits(spec, actions)
    assert result["attributes"]["main"] == {"cidr_block": "10.0.0.0/16"}
    # Original should be untouched
    assert spec["attributes"] == {}
    print("  apply add(attribute) ... OK")


def test_apply_attribute_merge():
    """Test that attribute add merges into existing attributes."""
    spec = {
        "resources": {"main": "aws_vpc.main"},
        "topology": {},
        "attributes": {"main": {"cidr_block": "10.0.0.0/16"}},
    }
    actions = [EditAction(op="add", field="attribute", value="main",
                          json_value={"enable_dns": True})]
    result = apply_edits(spec, actions)
    assert result["attributes"]["main"] == {
        "cidr_block": "10.0.0.0/16",
        "enable_dns": True,
    }
    print("  apply attribute merge ... OK")


def test_apply_attribute_remove():
    """Test applying an attribute remove action."""
    spec = {
        "resources": {"main": "aws_vpc.main", "web": "aws_instance.web"},
        "topology": {},
        "attributes": {
            "main": {"cidr_block": "10.0.0.0/16"},
            "web": {"instance_type": "t2.micro"},
        },
    }
    actions = [EditAction(op="remove", field="attribute", value="web")]
    result = apply_edits(spec, actions)
    assert "web" not in result["attributes"]
    assert "main" in result["attributes"]
    print("  apply remove(attribute) ... OK")


def test_live_llm():
    """Integration test: generate edits with attributes via LLM."""
    from src.utils.llm import LLM
    from src.iac_generator import IacGenerator

    spec = {
        "resources": {
            "main": "aws_vpc.main",
            "sub1": "aws_subnet.sub1",
        },
        "topology": {
            "sub1": ["main"],
        },
        "attributes": {},
    }

    llm = LLM(stateful=False)
    gen = IacGenerator(llm)

    response = gen.generate_edits(
        spec,
        feedback="Missing attributes: vpc needs cidr_block, subnet needs cidr_block and availability_zone",
        n=2,
    )
    print("\n=== LLM Response ===")
    print(response)

    actions = parse_edits(response)
    print(f"\n=== Parsed Actions ({len(actions)}) ===")
    for a in actions:
        print(f"  {a}")

    # Apply first option's actions
    option_actions = []
    in_option = False
    for line in response.split("\n"):
        if "### Option 1 ###" in line:
            in_option = True
            continue
        if "### Option 2 ###" in line:
            break
        if in_option:
            option_actions.extend(parse_edits(line))

    if option_actions:
        result = apply_edits(spec, option_actions)
        print("\n=== Result Spec ===")
        print(json.dumps(result, indent=2))
    else:
        print("\nNo Option 1 actions found to apply.")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--live", action="store_true",
                        help="Run LLM integration test")
    args = parser.parse_args()

    print("Unit tests:")
    test_parse_attribute_add()
    test_parse_attribute_remove()
    test_parse_mixed()
    test_parse_nested_json()
    test_apply_attribute_add()
    test_apply_attribute_merge()
    test_apply_attribute_remove()
    print("\nAll unit tests passed.")

    if args.live:
        print("\n--- LLM Integration Test ---")
        test_live_llm()


if __name__ == "__main__":
    main()
