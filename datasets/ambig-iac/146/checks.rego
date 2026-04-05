package main

import future.keywords.in

default allow = false

# Check for DynamoDB table creation or update
dynamodb_table_modified(resources) {
some resource in resources
resource.type == "aws_dynamodb_table"
resource.change.actions[_] == "create"
}

# Check if point-in-time recovery is enabled
point_in_time_recovery_enabled(resource) {
resource.type == "aws_dynamodb_table"
resource.change.after.point_in_time_recovery[_].enabled == true
}

# Allow if DynamoDB table is modified and point-in-time recovery is enabled
allow {
dynamodb_table_modified(input.resource_changes)
some resource in input.resource_changes
point_in_time_recovery_enabled(resource)
}