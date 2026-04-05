package terraform.validation

default is_configuration_valid = false

default is_valid_r53_zone = false

default is_valid_vpc = false

default is_valid_zone_association = false

default is_valid_vpc_association = false

# Validate aws_route53_zone resource
is_valid_r53_zone {
    some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_route53_zone"
    resource.expressions.vpc[0].vpc_id.references[0]
    resource.expressions.name
}

is_valid_vpc {
    some i, j
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_vpc"
    resource.expressions.cidr_block
    resource.expressions.enable_dns_hostnames.constant_value == true
    resource.expressions.enable_dns_support.constant_value == true
    
    resource2 := input.configuration.root_module.resources[j]
    resource2.type == "aws_vpc"
    resource2.expressions.cidr_block
    resource2.expressions.enable_dns_hostnames.constant_value == true
    resource2.expressions.enable_dns_support.constant_value == true
}

is_valid_zone_association {
    some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_route53_zone_association"
    resource.expressions.vpc_id.references[0]
    resource.expressions.zone_id.references[0]
}

is_valid_vpc_association {
     some i
     resource := input.configuration.root_module.resources[i]
    resource.type == "aws_route53_vpc_association_authorization"
    resource.expressions.vpc_id.references[0]
    resource.expressions.zone_id.references[0]
}

# Combine all checks into a final rule
is_configuration_valid {
    is_valid_r53_zone
    is_valid_vpc
    is_valid_zone_association
    is_valid_vpc_association
}