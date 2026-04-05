package main

import future.keywords.in

default allow = false

# Check for Aurora MySQL RDS cluster creation
rds_cluster_created(resources) {
some resource in resources
resource.type == "aws_rds_cluster"
resource.change.actions[_] == "create"
}

# Check if the RDS cluster engine is Aurora MySQL
rds_cluster_engine_valid(resource) {
resource.type == "aws_rds_cluster"
resource.change.after.engine == "aurora-mysql"
}

# Aggregate checks for Aurora MySQL RDS
allow {
# RDS Cluster Checks
rds_cluster_created(input.resource_changes)
some resource in input.resource_changes
rds_cluster_engine_valid(resource)
}