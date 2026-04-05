"""
Utility functions for building dependency graphs from Terraform plan JSON files.
"""


import json
import argparse
from pathlib import Path
import subprocess
from typing import Any, Dict, Iterable, Set, List
from typing import Tuple
import networkx as nx

from src.utils.utils import cleanup_terraform


def build_graph_from_plan_json_file(
    plan_json_path: str | Path,
    *,
    include_depends_on: bool = True,
    include_data_resources: bool = True,
    normalize_to_resource_addresses: bool = False,
) -> nx.DiGraph:
    """
    Build a dependency graph from an existing Terraform plan JSON file.

    Nodes: resource addresses (from configuration.*.resources[*].address)
    Edges:
      - "reference": src -> each string in any *.references list under src.expressions
      - "depends_on": src -> each entry in src.depends_on (if enabled)

    Args:
        plan_json_path: Path to a terraform plan JSON produced by `terraform show -json`.
        include_depends_on: Whether to add edges from explicit depends_on arrays.
        include_data_resources: Whether to include mode=="data" resources as nodes/targets.
        normalize_to_resource_addresses: If True, map attribute refs like
            "aws_x.y.attr" -> "aws_x.y" (keeps a cleaner resource-level graph).
            (Note: references may include both "aws_x.y.attr" and "aws_x.y".)

    Returns:
        nx.DiGraph with node attrs:
          - type, name, mode, provider_config_key, schema_version, expressions
          - references (set[str]) and depends_on (list[str]) when present
    """
    plan_json_path = Path(plan_json_path)
    plan: Dict[str, Any] = json.loads(plan_json_path.read_text())

    g = nx.DiGraph()

    def walk(node: Any, fn) -> None:
        if isinstance(node, dict):
            fn(node)
            for v in node.values():
                walk(v, fn)
        elif isinstance(node, list):
            for x in node:
                walk(x, fn)

    def collect_references(subtree: Any) -> Set[str]:
        refs: Set[str] = set()

        def fn(d: Dict[str, Any]) -> None:
            v = d.get("references")
            if isinstance(v, list):
                for item in v:
                    if isinstance(item, str):
                        refs.add(item)

        walk(subtree, fn)
        return refs

    def iter_modules() -> Iterable[Dict[str, Any]]:
        config = plan.get("configuration", {})
        if not isinstance(config, dict):
            return
        root = config.get("root_module", {})
        if not isinstance(root, dict):
            return

        stack = [root]
        while stack:
            mod = stack.pop()
            yield mod
            for child in mod.get("child_modules", []) or []:
                if isinstance(child, dict):
                    stack.append(child)

    def iter_resources() -> Iterable[Dict[str, Any]]:
        for mod in iter_modules():
            for r in mod.get("resources", []) or []:
                if isinstance(r, dict):
                    yield r

    def normalize_ref(ref: str) -> str:
        if not normalize_to_resource_addresses:
            return ref
        # Best-effort: turn "type.name.attr..." into "type.name"
        # Handles "data.aws_x.y.attr" -> "data.aws_x.y"
        parts = ref.split(".")
        if len(parts) >= 2:
            if parts[0] == "data" and len(parts) >= 3:
                return ".".join(parts[:3])
            return ".".join(parts[:2])
        return ref

    # Add nodes
    for r in iter_resources():
        addr = r.get("address")
        if not isinstance(addr, str):
            continue
        mode = r.get("mode")
        if not include_data_resources and mode == "data":
            continue

        g.add_node(
            addr,
            type=r.get("type"),
            name=r.get("name"),
            mode=mode,
            provider_config_key=r.get("provider_config_key"),
            schema_version=r.get("schema_version"),
            expressions=r.get("expressions"),
        )

    # Add edges
    for r in iter_resources():
        src = r.get("address")
        if not isinstance(src, str):
            continue
        mode = r.get("mode")
        if not include_data_resources and mode == "data":
            continue

        refs = {normalize_ref(x) for x in collect_references(r.get("expressions", {}))}
        refs.discard(src)  # avoid self loops from normalization

        g.nodes[src]["references"] = set(refs)

        for dst in refs:
            if not include_data_resources and dst.startswith("data."):
                continue
            # Only add edge if destination node exists in the graph (is an actual resource)
            if dst in g.nodes:
                g.add_edge(src, dst, kind="reference")

        if include_depends_on:
            dep_list = r.get("depends_on", [])
            if isinstance(dep_list, list):
                deps = [normalize_ref(d) for d in dep_list if isinstance(d, str)]
                g.nodes[src]["depends_on"] = deps
                for dst in deps:
                    if not include_data_resources and dst.startswith("data."):
                        continue
                    # Only add edge if destination node exists in the graph (is an actual resource)
                    if dst in g.nodes:
                        g.add_edge(src, dst, kind="depends_on")

    return g


def build_tfgraph(workspace_dir: str, include_data_resources: bool = True) -> nx.DiGraph:
    """
    Build a graph from Terraform workspace directory.
    
    Args:
        workspace_dir (str): Terraform workspace directory
        include_data_resources (bool): Whether to include data resources in the graph

    Returns:
        nx.DiGraph: A NetworkX directed graph with HCL attributes on nodes
        
    Raises:
        Exception: If there are issues reading the DOT file or processing the graph
    """

    # init
    result = subprocess.run( ["terraform", "init", "--upgrade"], cwd=workspace_dir, capture_output=True, check=True, encoding='utf-8', timeout=30)
    if result.returncode != 0:
        print(f"Error initializing Terraform workspace: {result.stderr}")
        return nx.DiGraph()

    # graph
    result = subprocess.run(["terraform", "graph"], cwd=workspace_dir, capture_output=True, check=True, encoding='utf-8', timeout=30)
    if result.returncode != 0:
        print(f"Error generating graph: {result.stderr}")
        return nx.DiGraph()

    dot_filepath = Path(workspace_dir) / "graph.dot"
    dot_filepath.write_text(result.stdout)
    g = nx.drawing.nx_pydot.read_dot(dot_filepath)

    # pydot has a known quirk where it parses the literal string "\\n" as a node.
    # This is a parsing artifact - the DOT file from terraform graph is valid,
    # but pydot incorrectly interprets something (possibly related to how it handles
    # the "node [...]" attribute declaration or newline handling) as a node named "\\n".
    # This is NOT present in the actual DOT file content.
    # 
    # Additionally, pydot may also parse "node" as a node from "node [...]" declarations.
    # We filter out these invalid nodes that are not valid Terraform resource identifiers.
    invalid_nodes = []
    for node in list(g.nodes()):
        # Check if node is invalid:
        # 1. Literal "\n" or "\\n" strings (pydot parsing artifact)
        # 2. Empty strings or whitespace-only
        # 3. The string "node" (from "node [...]" attribute declarations in DOT)
        if (node in ('\\n', '\n', 'node') or 
            not node or 
            not isinstance(node, str) or
            node.strip() == '' or
            node.isspace()):
            invalid_nodes.append(node)
    
    # Remove invalid nodes and their associated edges
    if not include_data_resources:
        data_nodes = [node for node in g.nodes() if node.startswith("data.")]
        for data_node in data_nodes:
            g.remove_node(data_node)
            for edge in g.edges(data_node):
                g.remove_edge(edge[0], edge[1])
    
    for node in invalid_nodes:
        g.remove_node(node)

    # create a new graph with type and name attributes (Example: "aws_x.y", type = "aws_x", name = "y")
    g_new = nx.DiGraph()
    for node in g.nodes():
        type = node.split(".")[0]
        name = node.split(".")[1]
        g_new.add_node(node, type=type, name=name)
    for edge in g.edges():
        g_new.add_edge(edge[0], edge[1])
    return g_new


def extract_resources(g: nx.DiGraph) -> Dict[str, List[str]]:
    """
    Extract resources from the graph.

    returns:
        Dict[str, List[str]]:
        Ex: {
            "aws_x": ["aws_x.z", "aws_x.a"],
            "aws_y": ["aws_y.b"],
        }
    """
    resources = {}
    for node in g.nodes():
        parts = node.split(".")
        # For data resources like "data.aws_iam_policy_document.xxx",
        # use "data.aws_iam_policy_document" as the type.
        if len(parts) >= 3 and parts[0] == "data":
            rtype = f"{parts[0]}.{parts[1]}"
            name = parts[2]
        else:
            rtype = parts[0]
            name = parts[1] if len(parts) > 1 else node

        if rtype not in resources:
            resources[rtype] = []
        resources[rtype].append(name)
    return resources

def extract_edges(g: nx.DiGraph) -> List[Tuple[str, str]]:
    """
    Extract edges from the graph.
    """
    edges = []
    for edge in g.edges():
        edges.append((edge[0], edge[1]))
    return edges

def extract_topo(g: nx.DiGraph) -> Dict[str, List[str]]:
    """
    Extract the topology of the graph.

    returns:
        Dict[str, List[str]]:
        Ex: {
            "aws_x.y": ["aws_x.z", "aws_x.a"],
            "aws_x.z": ["aws_x.a"],
            "aws_x.a": []
        }
    """
    topo = {}
    for node in g.nodes():
        # loop through edges and add to topo
        for edge in g.edges(node):
            if edge[0] not in topo:
                topo[edge[0]] = []
            topo[edge[0]].append(edge[1])
    return topo

def extract_attributes(g: nx.DiGraph) -> Dict[str, Dict[str, Any]]:
    """
    Extract attributes from the graph. (only works for graph built from plan.json)
    
    returns:
        Dict[str, Dict[str, Any]]:
        Ex: {
            "aws_x.y": {
                "attr1": "value1",
                "attr2": "value2",
                ...
            }
        }
    """
    attributes = {}
    for node in g.nodes(data=True):
        attributes[node[0]] = node[1].get('expressions', {})
        # print(json.dumps(node[1]['expressions'], indent=4))
    return attributes


def test(args):

    plan_json_path = Path(args.workspace_dir) / "plan.json"
    g = build_graph_from_plan_json_file(plan_json_path)
    
    # print node and edge attributes
    # for node in g.nodes(data=True):
    #     # print(node)
    #     # pirnt attributes
    #     for attr, value in node[1].items():
    #         if attr == "expressions":
    #             print(f"  {attr}: {json.dumps(value, indent=4)}")
    #         else:
    #             print(f"  {attr}: {value}")
    #     print("-"*100)

    # print resources
    resources = extract_resources(g)
    for type, names in resources.items():
        print(f"{type}: {json.dumps(names, indent=4)}")
    print("-"*100)

    # attributes = extract_attributes(g)
    # for node, attrs in attributes.items():
    #     print(f"{node}: {json.dumps(attrs, indent=4)}")
    # print("-"*100)

    topo = extract_topo(g)
    for node, edges in topo.items():
        print(f"{node}: {json.dumps(edges, indent=4)}")
    print("-"*100)


def test_tfgraph(args):
    g = build_tfgraph(args.workspace_dir)
    
    resources = extract_resources(g)
    for type, names in resources.items():
        print(f"{type}: {json.dumps(names, indent=4)}")
    print("-"*100)
    
    topo = extract_topo(g)
    for node, edges in topo.items():
        print(f"{node}: {json.dumps(edges, indent=4)}")
    print("-"*100)

def parse_args():
    parser = argparse.ArgumentParser(
        description="Build dependency graph from Terraform workspace directory",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Example:
    uv run utils/build_deps.py -w ambig_iac/0
        """
    )
    parser.add_argument("-w", "--workspace_dir", required=True, help="Path to the Terraform workspace directory")
    args = parser.parse_args()
    return args

if __name__ == "__main__":
    args = parse_args()
    
    test(args)

    # print()
    # print("-"*100)
    # test_tfgraph(args)

    cleanup_terraform(args.workspace_dir)