package terraform.validation

default has_aws_eks_access_entry_example = false

has_aws_eks_access_entry_example {
    entry := input.planned_values.root_module.resources[_]
    entry.type == "aws_eks_access_entry"
    entry.name == "example"
    entry.values.cluster_name == input.planned_values.root_module.resources[_].values.name  # Ensures it's the correct reference to aws_eks_cluster.example
    entry.values.kubernetes_groups == ["group-1", "group-2"]
    entry.values.type == "STANDARD"
}