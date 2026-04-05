package s3_bucket_intelligent_tiering
import future.keywords.in

default valid := false

valid {
    some bucket in input.configuration.root_module.resources
    bucket.type == "aws_s3_bucket"
    bucket.expressions.bucket.constant_value == "mybucket"
    
    some intelligent_tiering in input.configuration.root_module.resources
    intelligent_tiering.type == "aws_s3_bucket_intelligent_tiering_configuration"
    bucket.address in intelligent_tiering.expressions.bucket.references
}

valid {
    some bucket in input.configuration.root_module.resources
    bucket.type == "aws_s3_bucket"
    bucket.expressions.bucket.constant_value == "mybucket"
    
    some intelligent_tiering in input.configuration.root_module.resources
    intelligent_tiering.type == "aws_s3_bucket_intelligent_tiering_configuration"
    intelligent_tiering.expressions.bucket.constant_value == bucket.expressions.bucket.constant_value
}