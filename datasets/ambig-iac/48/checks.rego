package terraform.validation

import future.keywords.in

default has_valid_resources = false


has_valid_kinesis_stream {
	some i
    resource := input.planned_values.root_module.resources[i]
    resource.type == "aws_kinesis_stream"
    resource.values.name
}

has_valid_kinesis_stream_consumer {
	some i
    resource := input.planned_values.root_module.resources[i]
    resource.type == "aws_kinesis_stream_consumer"
    resource.values.name
    role := input.configuration.root_module.resources[i]
    role.expressions.stream_arn
}

has_valid_resources {
	has_valid_kinesis_stream
    has_valid_kinesis_stream_consumer
}
