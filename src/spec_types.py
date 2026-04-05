"""
Spec type definitions for compact infrastructure representation.
"""

from typing import TypedDict, Dict, List


class Spec(TypedDict):
    resources: Dict[str, str]       # label -> "type.name"  e.g. {"main": "aws_vpc.main"}
    topology: Dict[str, List[str]]  # label -> [dep_label]  e.g. {"sub1": ["main"]}
    attributes: Dict[str, dict]     # label -> {attr: val}  reserved, not checked

def is_valid_spec(spec: dict) -> bool:
    """Check if a spec is valid."""
    if not isinstance(spec, dict):
        return False
    if not isinstance(spec["resources"], dict):
        return False
    if not isinstance(spec["topology"], dict):
        return False
    if not isinstance(spec["attributes"], dict):
        return False
    return True


def is_empty_spec(spec: dict) -> bool:
    """Check if a spec is empty.
    
    empty spec is {resources: {}, topology: {}, attributes: {}}
    """
    return spec["resources"] == {} and spec["topology"] == {} and spec["attributes"] == {}


# main
if __name__ == "__main__":
    spec = {"resources": {}, "topology": {}, "attributes": {}}
    print(is_valid_spec(spec))
    print(is_empty_spec(spec))