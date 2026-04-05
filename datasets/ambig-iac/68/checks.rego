package terraform.validation

default has_aws_eks_fargate_profile_example = false

has_aws_eks_fargate_profile_example {
    fargate_profile := input.configuration.root_module.resources[_]
    fargate_profile.type == "aws_eks_fargate_profile"
    fargate_profile.name == "example"
    contains(fargate_profile.expressions.cluster_name.references[_], "aws_eks_cluster.example")  # Ensures it references aws_eks_cluster.example correctly
    fargate_profile.expressions.fargate_profile_name.constant_value == "example"
    contains(fargate_profile.expressions.pod_execution_role_arn.references[_], "aws_iam_role.example")  # Ensures it references aws_iam_role.example correctly
    count(fargate_profile.expressions.subnet_ids.references) > 0  # Ensure that subnet_ids is populated
    fargate_profile.expressions.selector[_].namespace.constant_value == "example"
}