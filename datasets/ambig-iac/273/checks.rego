package terraform.validation

default is_valid_efs_setup = false

# Rule to check if a valid aws_efs_file_system and aws_efs_file_system_policy exists
is_valid_efs_setup {
    has_valid_efs_file_system
    has_valid_aws_efs_backup_policy
}

# Helper rule to check if a valid aws_efs_file_system exists
has_valid_efs_file_system {
    resource := input.configuration.root_module.resources[_]
    resource.type == "aws_efs_file_system"
}

# Helper rule to check if a valid aws_efs_file_system_policy exists with required arguments
has_valid_aws_efs_backup_policy {
    resource := input.configuration.root_module.resources[_]
    resource.type == "aws_efs_backup_policy"
    resource.expressions.backup_policy
    resource.expressions.file_system_id
}
