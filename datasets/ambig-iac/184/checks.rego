package s3_bucket_accelerate
import future.keywords.in

default valid := false

valid {
        some bucket in input.configuration.root_module.resources
        bucket.type == "aws_s3_bucket"
        bucket.expressions.bucket.constant_value == "mybucket"

        some accelerate_config in input.configuration.root_module.resources
        accelerate_config.type == "aws_s3_bucket_accelerate_configuration"
        bucket.address in accelerate_config.expressions.bucket.references
        accelerate_config.expressions.status.constant_value == "Enabled"
}

valid {
        some bucket in input.configuration.root_module.resources
        bucket.type == "aws_s3_bucket"
        bucket.expressions.bucket.constant_value == "mybucket"

        some accelerate_config in input.configuration.root_module.resources
        accelerate_config.type == "aws_s3_bucket_accelerate_configuration"
        accelerate_config.expressions.bucket.constant_value == bucket.expressions.bucket.constant_value
        accelerate_config.expressions.status.constant_value == "Enabled"
}
