package main

import future.keywords.in

default allow = false

aws_redshift_cluster_valid(resources) {
    some resource in resources
    resource.type == "aws_redshift_cluster"
    resource.change.after.number_of_nodes == 2
}

aws_redshift_resource_policy_valid(resources) {
    some resource in resources
    resource.type == "aws_redshift_resource_policy"
}

# Aggregate all checks
allow {
    aws_redshift_cluster_valid(input.resource_changes)
    aws_redshift_resource_policy_valid(input.resource_changes)
}
