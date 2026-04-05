package aws_s3_bucket_notification
import future.keywords.in

default valid := false

valid { # IF THE BUCKET IS REFERRED TO BY ID
    some bucket in input.configuration.root_module.resources
    bucket.type == "aws_s3_bucket"
    
    some sns_topic in input.configuration.root_module.resources
    sns_topic.type == "aws_sns_topic"

    some notification in input.configuration.root_module.resources
    notification.type = "aws_s3_bucket_notification"
    bucket.address in notification.expressions.bucket.references
    some topic in notification.expressions.topic
    some event in topic.events.constant_value
    event == "s3:ObjectCreated:*"
    topic.filter_suffix.constant_value == ".log"
    sns_topic.address in topic.topic_arn.references
}

valid { # IF THE BUCKET IS REFFERED TO BY NAME
    some bucket in input.configuration.root_module.resources
    bucket.type == "aws_s3_bucket"

    some sns_topic in input.configuration.root_module.resources
    sns_topic.type == "aws_sns_topic"

    some notification in input.configuration.root_module.resources
    notification.type = "aws_s3_bucket_notification"
    bucket.expressions.bucket.constant_value == notification.expressions.bucket.constant_value
    some topic in notification.expressions.topic
    some event in topic.events.constant_value
    event == "s3:ObjectCreated:*"
    topic.filter_suffix.constant_value == ".log"
    sns_topic.address in topic.topic_arn.references
}