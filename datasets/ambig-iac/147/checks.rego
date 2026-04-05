package main

import future.keywords.in

default allow = false

# Check for DynamoDB table creation or update
dynamodb_table_modified(resources) {
some resource in resources
resource.type == "aws_dynamodb_table"
resource.change.actions[_] == "create"
}

# Check if TTL is enabled with the correct attribute name
ttl_configured(resource) {
resource.type == "aws_dynamodb_table"
resource.change.after.ttl[_].enabled == true
resource.change.after.ttl[_].attribute_name == "custom_ttl_attribute"
}

# Allow if DynamoDB table is modified and TTL is configured correctly
allow {
dynamodb_table_modified(input.resource_changes)
some resource in input.resource_changes
ttl_configured(resource)
}