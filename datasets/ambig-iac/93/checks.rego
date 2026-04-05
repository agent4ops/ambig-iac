package main

import future.keywords.in

default allow = false

aws_redshift_cluster_valid(resources) {
    some resource in resources
    resource.type == "aws_redshift_cluster"
    resource.change.after.number_of_nodes == 2
}

# Function to check if Redshift snapshot schedule is every 12 hours
aws_redshift_endpoint_authorization_valid(resources) {
    some resource in resources
    resource.type == "aws_redshift_endpoint_authorization"
    resource.change.after.account == "012345678910"
}

# Aggregate all checks
allow {
    aws_redshift_cluster_valid(input.resource_changes)
    aws_redshift_endpoint_authorization_valid(input.resource_changes)
}