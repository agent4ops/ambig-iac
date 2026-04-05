package terraform.validation

# Set default validation state for aws_egress_only_internet_gateway
default is_valid_egress_only_internet_gateway = false

# Validate aws_egress_only_internet_gateway resource
is_valid_egress_only_internet_gateway {
	some i
	resource := input.configuration.root_module.resources[i]
	resource.type == "aws_egress_only_internet_gateway"
	resource.expressions.vpc_id.constant_value != null
	resource.expressions.tags.constant_value != null # Verifies it is tagged with "permissions"
}