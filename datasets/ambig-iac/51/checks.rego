package terraform.validation

import future.keywords.in

default has_valid_resources = false

has_valid_iam_role(resources) { 
	some resource in resources 
    resource.type == "aws_iam_role" 
    contains(resource.change.after.assume_role_policy,"kinesisanalytics.amazonaws.com") 
}


has_valid_kinesisanalyticsv2_application {
	some i
	resource := input.planned_values.root_module.resources[i]
    resource.type == "aws_kinesisanalyticsv2_application"
    resource.values.name
    resource.values.runtime_environment == "SQL-1_0"
   	role := input.configuration.root_module.resources[i]
    role.expressions.service_execution_role
}

has_valid_resources {
	has_valid_iam_role(input.resource_changes)
    has_valid_kinesisanalyticsv2_application
}