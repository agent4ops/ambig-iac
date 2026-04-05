package terraform.validation

default is_configuration_valid = false

default is_valid_r53_zone = false

default is_valid_r53_record_na = false

default is_valid_r53_record_eu = false



# Validate aws_route53_zone resource
is_valid_r53_zone {
        some i
        resource := input.configuration.root_module.resources[i]
    resource.type == "aws_route53_zone"

}

# Validate aws_route53_record
is_valid_r53_record_na {
        some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_route53_record"
    resource.expressions.name
    resource.expressions.latency_routing_policy[0].region.constant_value == "us-east-1"
    resource.expressions.type
    resource.expressions.ttl
    resource.expressions.records
    resource.expressions.set_identifier
    resource.expressions.zone_id.references[0] == "aws_route53_zone.primary.zone_id"

}

is_valid_r53_record_eu {
        some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_route53_record"
    resource.expressions.name
    resource.expressions.latency_routing_policy[0].region.constant_value == "eu-central-1"
    resource.expressions.type
    resource.expressions.ttl
    resource.expressions.records
    resource.expressions.set_identifier
    resource.expressions.zone_id.references[0] == "aws_route53_zone.primary.zone_id"
}



# Combine all checks into a final rule
is_configuration_valid {
    is_valid_r53_zone
    is_valid_r53_record_na
    is_valid_r53_record_eu
}



