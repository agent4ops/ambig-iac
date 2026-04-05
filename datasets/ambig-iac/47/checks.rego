package terraform.validation

import future.keywords.in

default has_valid_resources = false

has_valid_kinesis_video_stream {
	some i
    resource := input.planned_values.root_module.resources[i]
    resource.type == "aws_kinesis_video_stream"
    resource.values.name
}

has_valid_resources {
	has_valid_kinesis_video_stream
}