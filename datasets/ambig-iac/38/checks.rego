package terraform.validation

import future.keywords.in

default has_valid_resources = false

has_valid_iam_role(resources) { 
        some resource in resources 
    resource.type == "aws_iam_role" 
    contains(resource.change.after.assume_role_policy,"firehose.amazonaws.com") 
}

has_valid_bucket {
    some i
    resource := input.planned_values.root_module.resources[i]
    resource.type == "aws_s3_bucket"
}

has_valid_firehose_delivery_stream {
        some i
        resource := input.planned_values.root_module.resources[i]
    resource.type == "aws_kinesis_firehose_delivery_stream"
    resource.values.name
    resource.values.destination == "extended_s3"
    resource.values.extended_s3_configuration[_].dynamic_partitioning_configuration
        role := input.configuration.root_module.resources[i]
    role.expressions.extended_s3_configuration[_].role_arn
}

has_valid_resources {
        has_valid_iam_role(input.resource_changes)
        has_valid_bucket
    has_valid_firehose_delivery_stream
}