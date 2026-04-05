package aws_redshift_cluster_parameter_event_subscription
import future.keywords.in

default valid := false

valid {
	some topic in input.configuration.root_module.resources
	topic.type == "aws_sns_topic"

	some param_group in input.configuration.root_module.resources
	param_group.type == "aws_redshift_parameter_group"

	some cluster in input.configuration.root_module.resources
	cluster.type == "aws_redshift_cluster"
	param_group.address in cluster.expressions.cluster_parameter_group_name.references

	some event_sub in input.configuration.root_module.resources
	event_sub.type == "aws_redshift_event_subscription"
	event_sub.expressions.source_type.constant_value == "cluster-parameter-group"
	topic.address in event_sub.expressions.sns_topic_arn.references
	param_group.address in event_sub.expressions.source_ids.references
}