package terraform.validation

import future.keywords.in

default has_valid_resources = false

has_valid_iam_role(resources) { 
    some resource in resources 
    resource.type == "aws_iam_role" 
    contains(resource.change.after.assume_role_policy,"kendra.amazonaws.com") 
}

has_valid_kendra_index {
        some i
    resource := input.planned_values.root_module.resources[i]
    resource.type == "aws_kendra_index"
    resource.values.name
    role := input.configuration.root_module.resources[i]
    role.expressions.role_arn
}

has_valid_kendra_data_source{
        some i
    resource := input.planned_values.root_module.resources[i]
    resource.type == "aws_kendra_data_source"
    resource.values.name
    resource.values.type
    resource.values.configuration[_].web_crawler_configuration[_].proxy_configuration
    role := input.configuration.root_module.resources[i]
    role.expressions.role_arn
    role.expressions.index_id
}


has_valid_resources {
    has_valid_iam_role(input.resource_changes)
    has_valid_kendra_index
    has_valid_kendra_data_source
}