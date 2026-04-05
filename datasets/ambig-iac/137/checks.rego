package main

import future.keywords.in

default allow = false

# Required AZs
required_azs := ["us-east-1a", "us-east-1b", "us-east-1c"]

# Check for RDS cluster creation
rds_cluster_created(resources) {
some resource in resources
resource.type == "aws_rds_cluster"
resource.change.actions[_] == "create"
}

# Check if engine is MySQL
rds_engine_mysql(resource) {
resource.type == "aws_rds_cluster"
resource.change.after.engine == "mysql"
}

# Check if AZs are correct and storage is 100GB
azs_and_storage_valid(resource) {
resource.type == "aws_rds_cluster"
resource.change.after.availability_zones == required_azs
resource.change.after.allocated_storage == 100
}

# Aggregate checks for RDS cluster
allow {
rds_cluster_created(input.resource_changes)
some resource in input.resource_changes
rds_engine_mysql(resource)
azs_and_storage_valid(resource)
}