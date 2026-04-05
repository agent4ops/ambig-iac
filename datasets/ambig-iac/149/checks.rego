package main

import future.keywords.in

default allow = false

# Check for DynamoDB table creation or update
dynamodb_table_modified(resources) {
some resource in resources
resource.type == "aws_dynamodb_table"
resource.change.actions[_] == "create"
}

# Check if stream is enabled with new and old images
stream_configured(resource) {
resource.type == "aws_dynamodb_table"
resource.change.after.stream_enabled == true
resource.change.after.stream_view_type == "NEW_AND_OLD_IMAGES" 
}

# Allow if DynamoDB table is modified and stream is configured correctly
allow {
dynamodb_table_modified(input.resource_changes)
some resource in input.resource_changes
stream_configured(resource)
}