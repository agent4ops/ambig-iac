package s3_bucket_analytics
import future.keywords.in

default valid := false

valid {
        some bucket in input.configuration.root_module.resources
        bucket.type == "aws_s3_bucket"
        bucket.expressions.bucket.constant_value == "mybucket"

        some other_bucket in input.configuration.root_module.resources
        other_bucket.type == "aws_s3_bucket"
        not bucket == other_bucket

        some analytics in input.configuration.root_module.resources
        analytics.type == "aws_s3_bucket_analytics_configuration"
        bucket.address in analytics.expressions.bucket.references
    some export in analytics.expressions.storage_class_analysis
    some dest in export.data_export
    some bucket_dest in dest.destination
    some arn in bucket_dest.s3_bucket_destination
    other_bucket.address in arn.bucket_arn.references
}