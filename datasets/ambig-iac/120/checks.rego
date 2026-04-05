package main

import future.keywords.in

default allow = false

# Check for MSK Cluster creation
msk_cluster_created(resources) {
some resource in resources
resource.type == "aws_msk_cluster"
resource.change.actions[_] == "create"
}

# Check for number of broker nodes (3)
broker_node_count_valid(resource) {
resource.type == "aws_msk_cluster"
resource.change.after.number_of_broker_nodes == 3
}


# Aggregate all checks
allow {
msk_cluster_created(input.resource_changes)
some resource in input.resource_changes
broker_node_count_valid(resource)
}