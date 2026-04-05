package main

import future.keywords.in

default allow = false

# Check if AWS DynamoDB table is being created with specific read and write capacity settings
aws_dynamodb_table_custom_capacity_valid(resources) {
    some resource in resources
    resource.type == "aws_dynamodb_table"
    resource.change.after.read_capacity == 20
    resource.change.after.write_capacity == 20

}

# Aggregate all checks
allow {
    aws_dynamodb_table_custom_capacity_valid(input.resource_changes)
}