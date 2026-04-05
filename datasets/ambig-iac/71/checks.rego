package terraform.validation

default has_aws_eks_node_group_example = false

has_aws_eks_node_group_example {
    node_group := input.planned_values.root_module.resources[_]
    node_group.type == "aws_eks_node_group"
    node_group.values.cluster_name == input.planned_values.root_module.resources[_].values.name
    node_group.values.node_group_name == "example"
    node_group.values.scaling_config[_].desired_size == 1
    node_group.values.scaling_config[_].max_size == 2
    node_group.values.scaling_config[_].min_size == 1
    node_group.values.update_config[_].max_unavailable == 1

    node_group2 := input.configuration.root_module.resources[_]
    node_group2.expressions.node_role_arn.references != null
    node_group2.expressions.subnet_ids != null

    count(node_group2.depends_on) == 3
    # Checking for AmazonEKSWorkerNodePolicy:
    worker_policy := input.configuration.root_module.resources[_]
    contains(node_group2.depends_on[_], worker_policy.name)
    contains(worker_policy.expressions.policy_arn.constant_value, "AmazonEKSWorkerNodePolicy")

    # Checking for AmazonEKS_CNI_Policy:
    worker_policy2 := input.configuration.root_module.resources[_]
    contains(node_group2.depends_on[_], worker_policy2.name)
    contains(worker_policy2.expressions.policy_arn.constant_value, "AmazonEKS_CNI_Policy")

    # Checking for AmazonEC2ContainerRegistryReadOnly:
    worker_policy3 := input.configuration.root_module.resources[_]
    contains(node_group2.depends_on[_], worker_policy3.name)
    contains(worker_policy3.expressions.policy_arn.constant_value, "AmazonEC2ContainerRegistryReadOnly")
}