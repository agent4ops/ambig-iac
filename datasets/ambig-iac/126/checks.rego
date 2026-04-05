package main

import future.keywords.in

default allow = false

# Check if any MSK cluster is being created
msk_cluster_created(resources) {
some resource in resources
resource.type == "aws_msk_cluster"
resource.change.actions[_] == "create"
}

# Check if encryption at rest is enabled (within after_unknown)
encryption_at_rest_enabled(resource) {
resource.type == "aws_msk_cluster"
resource.change.after_unknown.encryption_info[_].encryption_at_rest_kms_key_arn
}

# Aggregate all checks
allow {
msk_cluster_created(input.resource_changes)
some resource in input.resource_changes
encryption_at_rest_enabled(resource)
}