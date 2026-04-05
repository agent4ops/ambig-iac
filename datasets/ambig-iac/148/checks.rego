package main

import future.keywords.in

default allow = false

dynamodb_table_modified(resources) {
some resource in resources
resource.type == "aws_dynamodb_table"
resource.change.actions[_] == "create"
}

encryption_at_rest_enabled(resource) {
resource.type == "aws_dynamodb_table"
resource.change.after.server_side_encryption[_].enabled == true
}

allow {
dynamodb_table_modified(input.resource_changes)
some resource in input.resource_changes
encryption_at_rest_enabled(resource)
}