package terraform.validation

default has_aws_iam_role_fargate = false
default has_aws_iam_role_policy_attachment_fargate = false
default has_aws_eks_fargate_profile = false
default has_aws_eks_cluster_auth = false
default has_null_resource_k8s_patcher = false

has_aws_iam_role_fargate {
    role := input.planned_values.root_module.resources[_]
    role.type == "aws_iam_role"
    role.name == "eks-fargate-profile"
    role.values.name == "eks-fargate-profile"
    role.values.assume_role_policy != null
}

has_aws_iam_role_policy_attachment_fargate {
    attachment := input.planned_values.root_module.resources[_]
    attachment.type == "aws_iam_role_policy_attachment"
    attachment.name == "eks-fargate-profile"
    attachment.values.policy_arn == "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
    attachment.values.role == input.planned_values.root_module.resources[_].values.name  # Ensure role is correctly referenced
}

has_aws_eks_fargate_profile {
    fargate_profile := input.configuration.root_module.resources[_]
    fargate_profile.type == "aws_eks_fargate_profile"
    fargate_profile.name == "kube-system"
    fargate_profile.expressions.cluster_name != null
    fargate_profile.expressions.fargate_profile_name.constant_value == "kube-system"
    fargate_profile.expressions.pod_execution_role_arn != null
    count(fargate_profile.expressions.subnet_ids.references) == 4  # Ensure there are two subnet IDs
    fargate_profile.expressions.selector[_].namespace.constant_value == "kube-system"
}

has_aws_eks_cluster_auth {
    cluster_auth := input.configuration.root_module.resources[_]
    cluster_auth.type == "aws_eks_cluster_auth"
    cluster_auth.name != null  # Check for proper referencing
}

has_null_resource_k8s_patcher {
    k8s_patcher := input.configuration.root_module.resources[_]
    k8s_patcher.type == "null_resource"
    k8s_patcher.name == "k8s_patcher"
    k8s_patcher.depends_on != null
    count(k8s_patcher.expressions.triggers.references) == 8  # Check for three triggers
    k8s_patcher.provisioners[0].type == "local-exec"
    k8s_patcher.provisioners[0].expressions.command != null
}

valid_configuration {
    has_aws_iam_role_fargate
    has_aws_iam_role_policy_attachment_fargate
    has_aws_eks_fargate_profile
    has_aws_eks_cluster_auth
    has_null_resource_k8s_patcher
}