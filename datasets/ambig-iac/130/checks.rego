package main

import future.keywords.in

default allow = false

# Check if MSK cluster is serverless
is_serverless(resource) {
resource.type == "aws_msk_serverless_cluster"
}


# Check if cluster spans three AZs
has_three_azs(resource) {
resource.type == "aws_msk_serverless_cluster"
count(resource.expressions.vpc_config[_].subnet_ids.references) == 6
}

msk_cluster_region_valid(resource) {
input.configuration.provider_config.aws.expressions.region.constant_value == "us-east-1"
}

# Main rule combining all checks
allow {
some resource in input.configuration.root_module.resources
is_serverless(resource)
has_three_azs(resource)
msk_cluster_region_valid(resource)
}