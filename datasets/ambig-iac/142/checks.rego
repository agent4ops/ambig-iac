package main

import future.keywords.in

default allow = false

# Check for DynamoDB table creation
dynamodb_table_created(resources) {
some resource in resources
resource.type == "aws_dynamodb_table"
resource.change.actions[_] == "create"
}

# Check if read and write capacity are both set to 10
capacity_valid(resource) {
resource.type == "aws_dynamodb_table"
resource.change.after.read_capacity == 10
resource.change.after.write_capacity == 10
}

# Aggregate checks for DynamoDB table creation with specific capacity
allow {
dynamodb_table_created(input.resource_changes)
some resource in input.resource_changes
capacity_valid(resource)
}