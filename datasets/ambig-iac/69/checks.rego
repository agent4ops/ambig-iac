package terraform.validation

default has_aws_iam_role_example = false
default has_aws_iam_role_policy_attachment_example = false

has_aws_iam_role_example {
    role := input.planned_values.root_module.resources[_]
    role.type == "aws_iam_role"
    role.values.name == "eks-fargate-profile-example"
    # Ensure the assume role policy is correctly configured
    role.values.assume_role_policy == "{\"Statement\":[{\"Action\":\"sts:AssumeRole\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"eks-fargate-pods.amazonaws.com\"}}],\"Version\":\"2012-10-17\"}"
}

has_aws_iam_role_policy_attachment_example {
    attachment := input.planned_values.root_module.resources[_]
    attachment.type == "aws_iam_role_policy_attachment"
    attachment.name == "example-AmazonEKSFargatePodExecutionRolePolicy"
    attachment.values.policy_arn == "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
    # Check if the role is correctly referenced
    attachment.values.role == input.planned_values.root_module.resources[_].values.name
}

valid_configuration {
    has_aws_iam_role_example
    has_aws_iam_role_policy_attachment_example
}