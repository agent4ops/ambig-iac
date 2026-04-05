package s3_bucket_logging
import future.keywords.in

default valid := false

valid {
    some bucket in input.configuration.root_module.resources
    bucket.type == "aws_s3_bucket"

    some other_bucket in input.configuration.root_module.resources
    other_bucket.type == "aws_s3_bucket"
    not bucket == other_bucket

    some logging in input.configuration.root_module.resources
    logging.type == "aws_s3_bucket_logging"
    logging.expressions.target_prefix.constant_value == "log/"
    
    bucket.address in logging.expressions.bucket.references
    other_bucket.address in logging.expressions.target_bucket.references
}

valid {
    some bucket in input.configuration.root_module.resources
    bucket.type == "aws_s3_bucket"

    some other_bucket in input.configuration.root_module.resources
    other_bucket.type == "aws_s3_bucket"
    not bucket == other_bucket

    some logging in input.configuration.root_module.resources
    logging.type == "aws_s3_bucket_logging"
    logging.expressions.target_prefix.constant_value == "log/"
    
    logging.expressions.bucket.constant_value == bucket.expressions.bucket.constant_value
    other_bucket.address in logging.expressions.target_bucket.references
}

valid {
    some bucket in input.configuration.root_module.resources
    bucket.type == "aws_s3_bucket"

    some other_bucket in input.configuration.root_module.resources
    other_bucket.type == "aws_s3_bucket"
    not bucket == other_bucket

    some logging in input.configuration.root_module.resources
    logging.type == "aws_s3_bucket_logging"
    logging.expressions.target_prefix.constant_value == "log/"
    
    bucket.address in logging.expressions.bucket.references
    logging.expressions.target_bucket.constant_value == other_bucket.expressions.bucket.constant_value
}

valid {
    some bucket in input.configuration.root_module.resources
    bucket.type == "aws_s3_bucket"

    some other_bucket in input.configuration.root_module.resources
    other_bucket.type == "aws_s3_bucket"
    not bucket == other_bucket

    some logging in input.configuration.root_module.resources
    logging.type == "aws_s3_bucket_logging"
    logging.expressions.target_prefix.constant_value == "log/"
    
    logging.expressions.bucket.constant_value == bucket.expressions.bucket.constant_value
    logging.expressions.target_bucket.constant_value == other_bucket.expressions.bucket.constant_value
}