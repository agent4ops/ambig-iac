package terraform.validation

default has_aws_eks_access_policy_association_example = false

has_aws_eks_access_policy_association_example {
    policy_assoc := input.planned_values.root_module.resources[_]
    policy_assoc.type == "aws_eks_access_policy_association"
    policy_assoc.name == "example"
    policy_assoc.values.cluster_name == input.planned_values.root_module.resources[_].values.name  # Ensures it references aws_eks_cluster.example
    policy_assoc.values.policy_arn == "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
    policy_assoc.values.access_scope[_].type == "namespace"
    policy_assoc.values.access_scope[_].namespaces == ["example-namespace"]
}