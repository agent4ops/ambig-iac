package main

import future.keywords.in

default allow = false

# Check if the AWS DynamoDB table is being created in us-east-1
aws_dynamodb_table(resources) {
    some resource in resources
    resource.type == "aws_dynamodb_table"
}

# Check if the AWS DynamoDB table replica is being created in us-east-2
aws_dynamodb_table_replica(resources) {
    some resource in resources
    resource.type == "aws_dynamodb_table_replica"
}

# Aggregate all checks
allow {
    aws_dynamodb_table(input.resource_changes)
    aws_dynamodb_table_replica(input.resource_changes)
}