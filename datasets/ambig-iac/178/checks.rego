package iam_user_ssh
import future.keywords.in

default valid := false

valid {
    some user_ssh_resource in input.configuration.root_module.resources
    user_ssh_resource.type == "aws_iam_user_ssh_key"

    some user_resource in input.configuration.root_module.resources
    user_resource.type == "aws_iam_user"
    user_resource.address in user_ssh_resource.expressions.username.references
}