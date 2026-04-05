package main

import future.keywords.in

default allow = false


aws_sagemaker_domain_valid(resources) {
    some resource in resources
    resource.type == "aws_sagemaker_domain"
}

aws_iam_role_valid(resources) {
    some resource in resources
    resource.type == "aws_iam_role"
}

aws_vpc_valid(resources) {
    some resource in resources
    resource.type == "aws_vpc"
}

aws_subnet_valid(resources) {
    some resource in resources
    resource.type == "aws_subnet"
}

aws_sagemaker_user_profile_valid(resources) {
    some resource in resources
    resource.type == "aws_sagemaker_user_profile"
}

# Aggregate all checks
allow {
    aws_sagemaker_domain_valid(input.resource_changes)
    aws_iam_role_valid(input.resource_changes)
    aws_vpc_valid(input.resource_changes)
    aws_subnet_valid(input.resource_changes)
    aws_sagemaker_user_profile_valid(input.resource_changes)
}