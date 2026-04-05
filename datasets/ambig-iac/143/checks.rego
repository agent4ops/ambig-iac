package main

import future.keywords.in

default allow = false

# Check for DAX cluster creation
dax_cluster_created(resources) {
some resource in resources
resource.type == "aws_dax_cluster"
resource.change.actions[_] == "create"
}

# Allow DAX cluster creation
allow {
dax_cluster_created(input.resource_changes)
}