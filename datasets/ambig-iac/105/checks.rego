package main

import future.keywords.in

default allow = false

# Check if AWS DynamoDB table is being created with specific read and write capacity settings
aws_dynamodb_table_item_valid(resources) {
    some resource in resources
    resource.type == "aws_dynamodb_table_item"

}

# Aggregate all checks
allow {
    aws_dynamodb_table_item_valid(input.resource_changes)
}