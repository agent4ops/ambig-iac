package terraform.validation

default has_aws_eks_cluster = false
default has_aws_iam_role = false
default has_aws_iam_role_policy_attachment_eks_cluster = false
default has_aws_iam_role_policy_attachment_eks_service = false

has_aws_eks_cluster {
    some i
    eks_cluster := input.configuration.root_module.resources[i]
    eks_cluster.type == "aws_eks_cluster"
    eks_cluster.expressions.name != null
    eks_cluster.expressions.role_arn != null
    eks_cluster.expressions.vpc_config[_].subnet_ids != null
    count(eks_cluster.expressions.vpc_config[_].subnet_ids) > 0
    count(eks_cluster.depends_on) > 0
    has_local_exec_provisioners(eks_cluster)
}


has_local_exec_provisioners(resource) {
    resource.provisioners != null
    local_exec_count := [provisioner | 
        provisioner := resource.provisioners[_]; 
        provisioner.type == "local-exec"
    ]
    count(local_exec_count) > 0
    has_local_exec_command(local_exec_count)
}


has_local_exec_command(provisioners) {
    some i
    provisioners[i].expressions.command != null
}

has_aws_iam_role {
    some i
    iam_role := input.planned_values.root_module.resources[i]
    iam_role.type == "aws_iam_role"
    iam_role.values.name != null
    iam_role.values.assume_role_policy != null
}


has_aws_iam_role_policy_attachment_eks_cluster {
    some i
    policy_attachment := input.planned_values.root_module.resources[i]
    policy_attachment.type == "aws_iam_role_policy_attachment"
    policy_attachment.values.policy_arn == "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}


has_aws_iam_role_policy_attachment_eks_service {
    some i
    policy_attachment := input.planned_values.root_module.resources[i]
    policy_attachment.type == "aws_iam_role_policy_attachment"
    policy_attachment.values.policy_arn == "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

valid_configuration {
    has_aws_eks_cluster
    has_aws_iam_role
    has_aws_iam_role_policy_attachment_eks_cluster
    has_aws_iam_role_policy_attachment_eks_service
}