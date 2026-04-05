package main

import future.keywords.in

default allow = false

# Check for RDS cluster creation
rds_cluster_created(resources) {
some resource in resources
resource.type == "aws_rds_cluster"
resource.change.actions[_] == "create"
}

# Check if storage per AZ is at least 1000 GB
storage_per_az_valid(resource) {
resource.type == "aws_rds_cluster"
resource.change.after.allocated_storage == 100
}

# Aggregate checks for RDS cluster
allow {
rds_cluster_created(input.resource_changes)
some resource in input.resource_changes
storage_per_az_valid(resource)
}