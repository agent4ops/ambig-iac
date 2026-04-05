package terraform.validation

default is_configuration_valid = false

default is_valid_r53_zone = false

default is_valid_r53_record = false

# Validate aws_route53_zone resource
is_valid_r53_zone {
        some i
        resource := input.configuration.root_module.resources[i]
    resource.type == "aws_route53_zone"
    resource.expressions.name.constant_value == "2.0.192.in-addr.arpa"
}

# Validate aws_route53_record
is_valid_r53_record {
        some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_route53_record"
    resource.expressions.name
    resource.expressions.type.constant_value == "PTR"
    resource.expressions.ttl
    resource.expressions.records.constant_value[0] == "host.example.com"
    resource.expressions.zone_id.references[0] == "aws_route53_zone.reverse_zone.zone_id"
}


# Combine all checks into a final rule
is_configuration_valid {
    is_valid_r53_zone
    is_valid_r53_record
}
