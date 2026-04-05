package terraform.validation

default is_configuration_valid = false

default is_valid_r53_zone = false

default is_valid_r53_record = false

default is_valid_elb = false



# Validate aws_route53_zone resource
is_valid_r53_zone {
        some i
        resource := input.configuration.root_module.resources[i]
    resource.type == "aws_route53_zone"
    resource.expressions.name

}

is_valid_elb {
        some i
        resource := input.configuration.root_module.resources[i]
    resource.type == "aws_elb"
    resource.expressions.availability_zones
    resource.expressions.listener[0]

}

is_valid_r53_record {
        some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_route53_record"
    resource.expressions.name
    resource.expressions.type
    resource.expressions.zone_id.references[0] == "aws_route53_zone.primary.zone_id"
    resource.expressions.alias[0].name.references[0] == "aws_elb.main.dns_name"
    resource.expressions.alias[0].zone_id.references[0] == "aws_elb.main.zone_id"
}




# Combine all checks into a final rule
is_configuration_valid {
    is_valid_r53_zone
    is_valid_elb
    is_valid_r53_record
}



