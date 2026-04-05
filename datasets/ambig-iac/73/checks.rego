package terraform.analysis

default has_aws_iam_role = false
default has_aws_iam_role_policy_attachment = false
default has_aws_eks_cluster = false

has_aws_iam_role {
    r := input.configuration.root_module.resources[_]
    r.type == "aws_iam_role"
    r.expressions.name.constant_value == "example"
    r.expressions.assume_role_policy
}

has_aws_iam_role_policy_attachment {
    r := input.configuration.root_module.resources[_]
    r.type == "aws_iam_role_policy_attachment"
    r.expressions.policy_arn.constant_value == "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    r.expressions.role.references != null
}

has_aws_eks_cluster {
    r := input.configuration.root_module.resources[_]
    r.type == "aws_eks_cluster"
    r.expressions.role_arn
    r.expressions.vpc_config[_].endpoint_private_access.constant_value == false
    r.expressions.vpc_config[_].endpoint_public_access.constant_value == true
    count(r.expressions.vpc_config[_].subnet_ids.references) == 4
}

valid_config {
    has_aws_iam_role
    has_aws_iam_role_policy_attachment
    has_aws_eks_cluster
}