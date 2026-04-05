package main

import future.keywords.in

default allow = false

# MSK Cluster Checks

# Check for MSK Cluster creation
msk_cluster_created(resources) {
some resource in resources
resource.type == "aws_msk_cluster"
resource.change.actions[_] == "create"
}

# Check if the MSK cluster is in us-east-1
msk_cluster_region_valid(resource) {
resource.type == "aws_msk_cluster"
input.configuration.provider_config.aws.expressions.region.constant_value == "us-east-1"
}

# Check if the MSK cluster has 3 broker nodes
broker_node_count_valid(resource) {
resource.type == "aws_msk_cluster"
resource.change.after.number_of_broker_nodes == 3
}

# Check if CloudWatch logging is enabled for broker logs
cloudwatch_logging_enabled(resource) {
resource.type == "aws_msk_cluster"
resource.change.after.logging_info[_].broker_logs[_].cloudwatch_logs[_].enabled == true
}

# Check if S3 logging is enabled for broker logs
s3_logging_enabled(resource) {
resource.type == "aws_msk_cluster"
resource.change.after.logging_info[_].broker_logs[_].s3[_].enabled == true
}

# Check if Kinesis Firehose logging is enabled for broker logs
firehose_logging_enabled(resource) {
resource.type == "aws_msk_cluster"
resource.change.after.logging_info[_].broker_logs[_].firehose[_].enabled == true
}

# Check if encryption at rest is enabled
encryption_at_rest_enabled(resource) {
resource.type == "aws_msk_cluster"
resource.change.after_unknown.encryption_info[_].encryption_at_rest_kms_key_arn
}

# Check if both jmx_exporter and node_exporter are enabled
prometheus_exporters_enabled(resource) {
resource.type == "aws_msk_cluster"
resource.change.after.open_monitoring[_].prometheus[_].jmx_exporter[_].enabled_in_broker == true
resource.change.after.open_monitoring[_].prometheus[_].node_exporter[_].enabled_in_broker == true
}

# MSK Connect Checks

# Check for MSK Connect Custom Plugin creation
msk_connect_plugin_created(resources) {
some resource in resources
resource.type == "aws_mskconnect_custom_plugin"
resource.change.actions[_] == "create"
}

# Check if the custom plugin uses a ZIP file
plugin_content_type_valid(resource) {
resource.type == "aws_mskconnect_custom_plugin"
resource.change.after.content_type == "ZIP"
}

# Check for MSK Connect Connector creation
msk_connect_connector_created(resources) {
some resource in resources
resource.type == "aws_mskconnect_connector"
resource.change.actions[_] == "create"
}

# Check if the connector uses the custom plugin
connector_uses_custom_plugin(resource) {
resource.type == "aws_mskconnect_connector"
input.resource_changes[_].type == "aws_mskconnect_custom_plugin"
}

# Aggregate checks for custom plugin and connector

# Aggregate all checks for MSK and MSK Connect
allow {
# MSK Cluster Checks
msk_cluster_created(input.resource_changes)
some resource in input.resource_changes
msk_cluster_region_valid(resource)
broker_node_count_valid(resource)
cloudwatch_logging_enabled(resource)
s3_logging_enabled(resource)
firehose_logging_enabled(resource)
encryption_at_rest_enabled(resource)
prometheus_exporters_enabled(resource)

# MSK Connect Checks
msk_connect_plugin_created(input.resource_changes)
some resource2 in input.resource_changes
plugin_content_type_valid(resource2)
msk_connect_connector_created(input.resource_changes)
some resource3 in input.resource_changes
connector_uses_custom_plugin(resource3)
}