package main

import future.keywords.in

default allow = false

# Function to check if a VPC is created in us-east-1
aws_vpc_valid(resources) {
    some resource in resources
    resource.type == "aws_vpc"
    resource.change.after.cidr_block == "10.0.0.0/16"
}

# Function to check if subnets are created in east-1a and east-1b
aws_subnets_valid(resources) {
    some resource in resources
    resource.type == "aws_subnet"
    resource.change.after.availability_zone in {"us-east-1a", "us-east-1b"}
    resource.change.after.cidr_block == "10.0.1.0/24"
}

# Function to check if a Redshift subnet group is created with subnets in east-1a and east-1b
aws_redshift_subnet_group_valid(root_module_resources) {
    some resource in root_module_resources
    resource.type == "aws_redshift_subnet_group"
    count(resource.expressions.subnet_ids.references) == 4
}

# Aggregate all checks
allow {
    aws_vpc_valid(input.resource_changes)
    aws_subnets_valid(input.resource_changes)
    aws_redshift_subnet_group_valid(input.configuration.root_module.resources)
}
