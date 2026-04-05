package main

import future.keywords.in

default allow = false

# Check if the AWS DynamoDB table is being created in us-east-1
aws_dax_cluster_valid(resources) {
    some resource in resources
    resource.type == "aws_dax_cluster"
    resource.change.after.node_type == "dax.r4.large"
    resource.change.after.replication_factor == 1
}

# Aggregate all checks
allow {
    aws_dax_cluster_valid(input.resource_changes)
}