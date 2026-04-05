package main

import future.keywords.in

default allow = false

# Function to check if Redshift cluster is set up for high availability
aws_redshift_cluster_ha_valid(resources) {
    some resource in resources
    resource.type == "aws_redshift_cluster"
    resource.change.after.cluster_type == "multi-node"
    resource.change.after.number_of_nodes > 1
    resource.change.after.cluster_subnet_group_name != null
}

aws_internet_gateway_valid(resources) {
    some resource in resources
    resource.type == "aws_internet_gateway"
}

# Function to check if subnets are created in east-1a and east-1b
aws_subnets_valid(resources) {
    subnet_a_valid(resources)
    subnet_b_valid(resources)
}

subnet_a_valid(resources) {
    some resource in resources
    resource.type == "aws_subnet"
    resource.change.after.availability_zone == "us-east-1a"
}

subnet_b_valid(resources) {
    some resource in resources
    resource.type == "aws_subnet"
    resource.change.after.availability_zone == "us-east-1b"
}

# Function to check if a Redshift subnet group spans across us-east-1a and us-east-1b
aws_redshift_subnet_group_valid(root_module_resources) {
    some resource in root_module_resources
    resource.type == "aws_redshift_subnet_group"
    count(resource.expressions.subnet_ids.references) == 4

}

# Aggregate all checks
allow {
    aws_redshift_cluster_ha_valid(input.resource_changes)
    aws_internet_gateway_valid(input.resource_changes)
    aws_subnets_valid(input.resource_changes)
    aws_redshift_subnet_group_valid(input.configuration.root_module.resources)
}
