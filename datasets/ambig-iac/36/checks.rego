package terraform.validation

import future.keywords.in

default has_valid_resources = false

has_valid_iam_role(resources) { 
        some resource in resources 
    resource.type == "aws_iam_role" 
    contains(resource.change.after.assume_role_policy,"kinesisanalytics.amazonaws.com") 
}

has_valid_kinesis_stream {
        some i
    resource := input.planned_values.root_module.resources[i]
    resource.type == "aws_kinesis_stream"
    resource.values.name
}

has_valid_kinesis_analytics_application {
        some i
        resource := input.planned_values.root_module.resources[i]
    resource.type == "aws_kinesis_analytics_application"
    resource.values.name
    resource.values.inputs[_].kinesis_stream
}

has_valid_resources {
        has_valid_iam_role(input.resource_changes)
        has_valid_kinesis_stream
    has_valid_kinesis_analytics_application
}