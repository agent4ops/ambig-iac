package terraform.validation

default is_valid_terraform_plan = false

# Rule to check for an AWS Glacier Vault resource with a 'name' attribute
is_valid_glacier_vault {
        resource := input.planned_values.root_module.resources[_]
        resource.type == "aws_glacier_vault"
        not is_null(resource.values.name)
}

# Rule to check for an AWS DLM Lifecycle Policy with required attributes
is_valid_dlm_lifecycle_policy {
        resource := input.planned_values.root_module.resources[_]
        resource.type == "aws_dlm_lifecycle_policy"
        not is_null(resource.values.description)
#         not is_null(resource.values.execution_role_arn)
        not is_null(resource.values.policy_details)
    
    execution_role_arn_configured(resource)
}

execution_role_arn_configured(_) {
    role_resource := input.configuration.root_module.resources[_]
    role_resource.type == "aws_dlm_lifecycle_policy"
#     role_resource.name == "dlm_lifecycle_role"
    not is_null(role_resource.expressions.execution_role_arn)
}

# Combined rule to validate the entire Terraform plan
is_valid_terraform_plan {
        is_valid_glacier_vault
        is_valid_dlm_lifecycle_policy
}