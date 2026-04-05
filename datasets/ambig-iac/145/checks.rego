package main

import future.keywords.in

default allow = false

# Check for DAX subnet group creation
dax_subnet_group_created(resources) {
some resource in resources
resource.type == "aws_dax_subnet_group"
resource.change.actions[_] == "create"
}

# Allow DAX subnet group creation with sufficient subnets
allow {
dax_subnet_group_created(input.resource_changes)
}