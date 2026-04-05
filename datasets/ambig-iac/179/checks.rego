package iam_group_basic
import future.keywords.in

default valid := false

valid {
    some group_resource in input.configuration.root_module.resources
    group_resource.type == "aws_iam_group"
}