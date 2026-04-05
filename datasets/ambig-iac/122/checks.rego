package main

import future.keywords.in

default allow = false

# Check if any MSK cluster is being created
msk_cluster_created(resources) {
some resource in resources
resource.type == "aws_msk_cluster"
resource.change.actions[_] == "create"
}

# Check if the MSK cluster is in us-east-1
msk_cluster_region_valid(resource) {
resource.type == "aws_msk_cluster"
input.configuration.provider_config.aws.expressions.region.constant_value == "us-east-2"
}

# Check if the MSK cluster has 3 broker nodes
broker_node_count_valid(resource) {
resource.type == "aws_msk_cluster"
resource.change.after.number_of_broker_nodes == 3
}

# Aggregate all checks
allow {
msk_cluster_created(input.resource_changes)
some resource in input.resource_changes
msk_cluster_region_valid(resource)
broker_node_count_valid(resource)
}