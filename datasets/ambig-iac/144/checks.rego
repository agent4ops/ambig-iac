package main

import future.keywords.in

default allow = false

# Check for DAX parameter group creation
dax_parameter_group_created(resources) {
some resource in resources
resource.type == "aws_dax_parameter_group"
resource.change.actions[_] == "create"
}

# Allow DAX parameter group creation with specific parameters
allow {
dax_parameter_group_created(input.resource_changes)
}