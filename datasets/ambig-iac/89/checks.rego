package main

import future.keywords.in

default allow = false

aws_elasticache_user_group_valid(resources) {
    some resource in resources
    resource.type == "aws_elasticache_user_group"
}

# Aggregate all checks
allow {
    aws_elasticache_user_group_valid(input.resource_changes)
}