package terraform.validation

default is_configuration_valid = false

default is_valid_r53_zone = false

default is_valid_r53_record = false

default is_valid_vpc = false

# Validate aws_vpc resource
is_valid_vpc {
        some i
        resource := input.configuration.root_module.resources[i]
        resource.type == "aws_vpc"
        resource.expressions.cidr_block != null
}


# Validate aws_route53_zone resource
is_valid_r53_zone {
	some i
	resource := input.configuration.root_module.resources[i]
    resource.type == "aws_route53_zone"
    resource.expressions.name.constant_value == "internal.example53.com"
    resource.expressions.vpc[0].vpc_id.references[0] == "aws_vpc.main.id"
}

# Validate aws_route53_record
is_valid_r53_record {
	some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_route53_record"
    resource.expressions.name
    resource.expressions.type
    resource.expressions.ttl
    resource.expressions.records
    resource.expressions.zone_id.references[0] == "aws_route53_zone.private_zone.zone_id"
}


# Combine all checks into a final rule
is_configuration_valid {
	is_valid_vpc
    is_valid_r53_zone
    is_valid_r53_record
}