package terraform.validation

default is_valid_efs_setup = false

# Rule to check if a valid aws_efs_file_system and aws_efs_file_system_policy exists
is_valid_efs_setup {
    has_valid_efs_file_system
    has_valid_aws_efs_mount_target
    is_valid_vpc
    is_valid_subnet
}

# Helper rule to check if a valid aws_efs_file_system exists
has_valid_efs_file_system {
    resource := input.configuration.root_module.resources[_]
    resource.type == "aws_efs_file_system"
}

# Helper rule to check if a valid aws_efs_file_system_policy exists with required arguments
has_valid_aws_efs_mount_target {
    resource := input.configuration.root_module.resources[_]
    resource.type == "aws_efs_mount_target"
    resource.expressions.file_system_id
    resource.expressions.subnet_id
}

has_valid_vpc {
    resource := input.configuration.root_module.resources[_]
    resource.type == "aws_efs_mount_target"
    resource.expressions.file_system_id
    resource.expressions.subnet_id
}


# has one vpc resource
is_valid_vpc {
        have_required_vpc_argument
}

have_required_vpc_argument {
        resource := input.configuration.root_module.resources[_]
        resource.type == "aws_vpc"
        resource.expressions.cidr_block.constant_value != null
}

have_required_vpc_argument {
        resource := input.configuration.root_module.resources[_]
        resource.type == "aws_vpc"
        resource.expressions.ipv4_ipam_pool_id.constant_value != null
}

# has valid subnet
is_valid_subnet {
        resource := input.configuration.root_module.resources[_]
        resource.type == "aws_subnet"
        resource.expressions.vpc_id != null
        have_required_subnet_argument
}

have_required_subnet_argument {
        resource := input.configuration.root_module.resources[_]
        resource.type == "aws_subnet"
        resource.expressions.cidr_block != null
}

have_required_subnet_argument {
        resource := input.configuration.root_module.resources[_]
        resource.type == "aws_subnet"
        resource.expressions.ipv6_cider_block != null
}