package terraform.validation

# Set default validation states
default is_valid_vpc = false

default is_valid_internet_gateway = false

default is_valid_route_table = false

default is_valid_subnets1 = false

default is_valid_subnets2 = false

default is_valid_security_group = false

default is_valid_db_subnet_group = false

# Validate aws_vpc resource
is_valid_vpc {
        some i
        resource := input.configuration.root_module.resources[i]
        resource.type == "aws_vpc"
        resource.expressions.cidr_block.constant_value != null
}

# Validate aws_subnet resources
is_valid_subnets1 {
        some i
        resource := input.configuration.root_module.resources[i]
        resource.type == "aws_subnet"
        resource.expressions.vpc_id.references[0] == "aws_vpc.main.id"
}

is_valid_subnets2 {
        some i
        resource := input.configuration.root_module.resources[i]
        resource.type == "aws_subnet"
        resource.expressions.vpc_id.references[0] == "aws_vpc.main.id"
}

# Validate aws_internet_gateway resource
is_valid_internet_gateway {
        some i
        resource := input.configuration.root_module.resources[i]
        resource.type == "aws_internet_gateway"
        resource.expressions.vpc_id.references[0] == "aws_vpc.main.id"
}

# Validate aws_route_table resource
is_valid_route_table {
        some i
        resource := input.configuration.root_module.resources[i]
        resource.type == "aws_route_table"
        resource.expressions.vpc_id.references[0] == "aws_vpc.main.id"
        resource.expressions.route.references[0] == "aws_internet_gateway.gateway.id"
}

# Validate aws_security_group resource
is_valid_security_group {
        some i
        resource := input.configuration.root_module.resources[i]
        resource.type == "aws_security_group"
        resource.expressions.vpc_id.references[0] == "aws_vpc.main.id"
    some j
        port1 := resource.expressions.ingress.constant_value[j]
    port1.from_port == 3306
    some k
        port2 := resource.expressions.ingress.constant_value[k]
    port2.from_port == 5432
}

# Validate aws_db_subnet_group resource
is_valid_db_subnet_group {
        some i
        resource := input.configuration.root_module.resources[i]
        resource.type == "aws_db_subnet_group"
}
