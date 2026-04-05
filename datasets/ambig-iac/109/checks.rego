package main

import future.keywords.in

default allow = false

# Check if the AWS DynamoDB table is being created in us-east-1
aws_dax_subnet_group_valid(resources) {
    some resource in resources
    resource.type == "aws_dax_subnet_group"
}

# Aggregate all checks
allow {
    aws_dax_subnet_group_valid(input.resource_changes)
}
