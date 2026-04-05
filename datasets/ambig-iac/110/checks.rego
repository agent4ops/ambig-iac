package main

import future.keywords.in

default allow = false

# Check if the AWS DynamoDB table is being created in us-east-1
aws_dynamodb_table_valid(resources) {
    some resource in resources
    resource.type == "aws_dynamodb_table"
    resource.change.after.billing_mode == "PAY_PER_REQUEST"
}

# Aggregate all checks
allow {
    aws_dynamodb_table_valid(input.resource_changes)
}
