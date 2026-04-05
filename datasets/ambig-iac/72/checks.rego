package terraform.validation

default has_aws_iam_policy_document_assume_role = false
default has_aws_iam_role_example = false
default has_aws_iam_role_policy_attachment_example_s3 = false
default has_aws_eks_pod_identity_association_example = false

has_aws_iam_policy_document_assume_role {
    assume_role := input.configuration.root_module.resources[_]
    assume_role.type == "aws_iam_policy_document"
    assume_role.expressions.statement[_].effect.constant_value == "Allow"
    assume_role.expressions.statement[_].principals[_].type.constant_value == "Service"
    assume_role.expressions.statement[_].principals[_].identifiers.constant_value[_] == "pods.eks.amazonaws.com"
    count(assume_role.expressions.statement[_].actions.constant_value) == 2
    assume_role.expressions.statement[_].actions.constant_value[_] == "sts:AssumeRole"
    assume_role.expressions.statement[_].actions.constant_value[_] == "sts:TagSession"
}

has_aws_iam_role_example {
    role := input.configuration.root_module.resources[_]
    role.type == "aws_iam_role"
    role.name == "example"
    role.expressions.assume_role_policy != null
}

has_aws_iam_role_policy_attachment_example_s3 {
    policy_attachment := input.configuration.root_module.resources[_]
    policy_attachment.type == "aws_iam_role_policy_attachment"
    policy_attachment.name == "example_s3"
    policy_attachment.expressions.policy_arn.constant_value == "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
    policy_attachment.expressions.role.references[_] == "aws_iam_role.example.name"
}

has_aws_eks_pod_identity_association_example {
    pod_identity := input.configuration.root_module.resources[_]
    pod_identity.type == "aws_eks_pod_identity_association"
    pod_identity.expressions.cluster_name.references[_] == "aws_eks_cluster.example.name"
    pod_identity.expressions.namespace.constant_value == "example"
    pod_identity.expressions.role_arn.references[_] == "aws_iam_role.example.arn"
}

valid_configuration {
    has_aws_iam_policy_document_assume_role
    has_aws_iam_role_example
    has_aws_iam_role_policy_attachment_example_s3
    has_aws_eks_pod_identity_association_example
}