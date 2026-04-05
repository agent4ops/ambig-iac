package terraform.validation

# Set default validation states
default is_valid_vpc = false

default is_valid_internet_gateway = false

# Validate aws_vpc resource
is_valid_vpc {
        some i
        resource := input.configuration.root_module.resources[i]
        resource.type == "aws_vpc"
        resource.expressions.cidr_block.constant_value == "10.0.0.0/16"
        resource.expressions.enable_dns_hostnames.constant_value == true
}

# Validate aws_internet_gateway resource
is_valid_internet_gateway {
        some i
        resource := input.configuration.root_module.resources[i]
        resource.type == "aws_internet_gateway"
        resource.expressions.vpc_id.references[0] == "aws_vpc._.id"
}
