package main

import future.keywords.in

default allow = false

aws_elasticache_cluster_valid(resources) {
    some resource in resources
    resource.type == "aws_elasticache_cluster"
    resource.change.after.engine == "memcached"
}

# Aggregate all checks
allow {
    aws_elasticache_cluster_valid(input.resource_changes)
}