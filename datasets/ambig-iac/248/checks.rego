package terraform.validation

default is_valid_terraform_plan = false

# Rule to check for an AWS Glacier Vault resource with 'name' and 'notification' attributes
is_valid_glacier_vault {
	resource := input.configuration.root_module.resources[_]
	resource.type == "aws_glacier_vault"
	not is_null(resource.name)
	not is_null(resource.expressions)
	not is_null(resource.expressions.notification[0].sns_topic)
	not is_null(resource.expressions.notification[0].events)
}


# Rule to check for the existence of an AWS SNS Topic resource
is_valid_sns_topic {
	sns_topic_resource := input.planned_values.root_module.resources[_]
	sns_topic_resource.type == "aws_sns_topic"
}

# Combined rule to validate the entire Terraform plan
is_valid_terraform_plan {
	is_valid_glacier_vault
	is_valid_sns_topic
}