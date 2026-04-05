package terraform.analysis

default has_aws_iam_role = false
default has_aws_iam_role_policy_attachment = false
default has_aws_eks_cluster = false

has_aws_iam_role {
    role := input.configuration.root_module.resources[_]
    role.type == "aws_iam_role"
    role.expressions.assume_role_policy
}

has_aws_iam_role_policy_attachment {
    policy_attachment := input.configuration.root_module.resources[_]
    policy_attachment.type == "aws_iam_role_policy_attachment"
    policy_attachment.expressions.policy_arn.constant_value == "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    policy_attachment.expressions.role 
}

has_aws_eks_cluster {
    cluster := input.configuration.root_module.resources[_]
    cluster.type = "aws_eks_cluster"
    cluster.expressions.name 
    cluster.expressions.version 
    cluster.expressions.role_arn
    cluster.expressions.vpc_config[_].endpoint_private_access.constant_value == false
    cluster.expressions.vpc_config[_].endpoint_public_access.constant_value == true
    cluster.expressions.vpc_config[_].subnet_ids
    count(cluster.expressions.vpc_config[_].subnet_ids.references) >= 4
}

valid_config {
    has_aws_iam_role
    has_aws_iam_role_policy_attachment
    has_aws_eks_cluster
}