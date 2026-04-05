package terraform.validation

default is_valid_terraform_plan = false

# Rule to check for an AWS Glacier Vault resource with 'name' and 'access_policy' attributes
is_valid_glacier_vault {
	resource := input.planned_values.root_module.resources[_]
	resource.type == "aws_glacier_vault"
	not is_null(resource.values.name)
}

# Rule to check for the existence of an AWS Glacier Vault Lock resource
is_valid_glacier_vault_lock {
	resource := input.planned_values.root_module.resources[_]
	resource.type == "aws_glacier_vault_lock"
}

# Combined rule to validate the entire Terraform plan
is_valid_terraform_plan {
	is_valid_glacier_vault
	is_valid_glacier_vault_lock
}