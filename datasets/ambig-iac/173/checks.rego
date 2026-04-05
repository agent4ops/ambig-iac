package aws_redshift_cluster_event_subscription
import future.keywords.in

default valid := false

valid {
        some topic in input.configuration.root_module.resources
        topic.type == "aws_sns_topic"
    
        some cluster in input.configuration.root_module.resources
        cluster.type == "aws_redshift_cluster"

        some event_sub in input.configuration.root_module.resources
        event_sub.type == "aws_redshift_event_subscription"
    event_sub.expressions.source_type.constant_value == "cluster"
        topic.address in event_sub.expressions.sns_topic_arn.references
        cluster.address in event_sub.expressions.source_ids.references
}