package main

import future.keywords.in

default allow = false

# Check for DynamoDB table creation
dynamodb_table_created(resources) {
some resource in resources
resource.type == "aws_dynamodb_table"
resource.change.actions[_] == "create"
}

# Check if point-in-time recovery is enabled
point_in_time_recovery_enabled(resource) {
resource.type == "aws_dynamodb_table"
resource.change.after.point_in_time_recovery[_].enabled == true
}

# Aggregate checks for DynamoDB table with PITR
allow {
dynamodb_table_created(input.resource_changes)
some resource in input.resource_changes
point_in_time_recovery_enabled(resource)
}