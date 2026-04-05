package main

import future.keywords.in

default allow = false

# Check if AWS Redshift cluster with 2 nodes is being created
aws_redshift_cluster_valid(resources) {
    some resource in resources
    resource.type == "aws_redshift_cluster"
    resource.change.after.number_of_nodes == 2
}

# Check if AWS Redshift endpoint access is being created
aws_redshift_endpoint_access_valid(resources) {
    some resource in resources
    resource.type == "aws_redshift_endpoint_access"
}

# Aggregate all checks
allow {
    aws_redshift_cluster_valid(input.resource_changes)
    aws_redshift_endpoint_access_valid(input.resource_changes)
}
