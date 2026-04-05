package terraform.validation

default is_configuration_valid = false

default is_valid_r53_zone = false


# Validate aws_route53_zone resource
is_valid_r53_zone {
	some i
	resource := input.configuration.root_module.resources[i]
    resource.type == "aws_route53_zone"
    resource.expressions.name.constant_value == "example53.com"
}


# Combine all checks into a final rule
is_configuration_valid {
    is_valid_r53_zone
}
