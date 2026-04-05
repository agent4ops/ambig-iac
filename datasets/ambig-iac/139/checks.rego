package main

import future.keywords.in

default allow = false

# Check for DB instance creation
db_instance_created(resources) {
some resource in resources
resource.type == "aws_db_instance"
resource.change.actions[_] == "create"
}

# Check if engine is MySQL
db_engine_mysql(resource) {
resource.type == "aws_db_instance"
resource.change.after.engine == "postgres"
}

# Aggregate checks for DB instance
allow {
db_instance_created(input.resource_changes)
some resource in input.resource_changes
db_engine_mysql(resource)
}