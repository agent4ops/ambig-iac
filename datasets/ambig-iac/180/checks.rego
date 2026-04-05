package iam_user_basic
import future.keywords.in

default valid := false

valid {
	some user_resource in input.configuration.root_module.resources
	user_resource.type == "aws_iam_user"
}