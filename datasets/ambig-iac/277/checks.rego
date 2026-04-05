package terraform.validation

default is_valid_vpc = false
default is_valid_internet_gateway = false
default is_valid_route_table = false

# Validate aws_vpc resource
is_valid_vpc {
    some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_vpc"
    resource.expressions.cidr_block != null
    resource.expressions.enable_dns_support.constant_value == true
    resource.expressions.enable_dns_hostnames.constant_value == true
    resource.expressions.instance_tenancy.constant_value == "dedicated"
    resource.expressions.tags.constant_value["Name"] != null
}

# Validate aws_internet_gateway resource
is_valid_internet_gateway {
    some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_internet_gateway"
    resource.expressions.vpc_id.references[0] == "aws_vpc.dgraph.id"
    resource.expressions.tags.constant_value["Name"] != null
}

# Validate aws_route_table resource
is_valid_route_table {
    some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_route_table"
    resource.expressions.vpc_id.references[0] == "aws_vpc.dgraph.id"
}
