package iam_mfa_basic
import future.keywords.in

default valid := false

valid {
	some mfa in input.configuration.root_module.resources
	mfa.type == "aws_iam_virtual_mfa_device"
}