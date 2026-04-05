package terraform.validation

# Set default validation states
default is_valid_vpc = false

default is_valid_dhcp_options = false

default is_valid_dhcp_options_association = false

# Validate aws_vpc resource
is_valid_vpc {
        some i
        resource := input.configuration.root_module.resources[i]
        resource.type == "aws_vpc"
        resource.expressions.cidr_block.constant_value == "192.168.0.0/16"
}

# Validate aws_vpc_dhcp_options resource
is_valid_dhcp_options {
        some i
        resource := input.planned_values.root_module.resources[i]
        resource.type == "aws_vpc_dhcp_options"
        resource.values.domain_name == "windomain.local"
    resource.values.domain_name_servers == ["192.168.56.102", "8.8.8.8"]
        resource.values.netbios_name_servers != null
}

# Validate aws_vpc_dhcp_options_association resource
is_valid_dhcp_options_association {
        some i
        resource := input.configuration.root_module.resources[i]
        resource.type == "aws_vpc_dhcp_options_association"
        resource.expressions.dhcp_options_id.references[0] == "aws_vpc_dhcp_options.default.id"
        resource.expressions.vpc_id.references[0] == "aws_vpc.default.id"
}
