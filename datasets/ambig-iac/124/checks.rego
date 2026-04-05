package main

import future.keywords.in

default allow = false

# Check if any MSK cluster is being created
msk_cluster_created(resources) {
some resource in resources
resource.type == "aws_msk_cluster"
resource.change.actions[_] == "create"
}

# Check if S3 logging is enabled for broker logs
s3_logging_enabled(resource) {
resource.type == "aws_msk_cluster"
resource.change.after.logging_info[_].broker_logs[_].s3[_].enabled == true
}

# Aggregate all checks
allow {
msk_cluster_created(input.resource_changes)
some resource in input.resource_changes
s3_logging_enabled(resource)
}