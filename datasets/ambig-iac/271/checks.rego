package terraform.validation

default is_valid_efs_file_system = false

# Rule to check if a valid aws_efs_file_system exists
is_valid_efs_file_system {
    resource := input.configuration.root_module.resources[_]
    resource.type == "aws_efs_file_system"
    resource.expressions.lifecycle_policy
}