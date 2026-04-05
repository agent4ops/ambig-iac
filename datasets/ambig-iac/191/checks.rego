package s3_bucket_object_lock
import future.keywords.in

default valid := false

valid {
        some bucket in input.configuration.root_module.resources
        bucket.type == "aws_s3_bucket"
        bucket.expressions.bucket.constant_value == "mybucket"
        bucket.expressions.object_lock_enabled.constant_value == true

        some object_lock in input.configuration.root_module.resources
        object_lock.type == "aws_s3_bucket_object_lock_configuration"
        bucket.address in object_lock.expressions.bucket.references
}

valid {
        some bucket in input.configuration.root_module.resources
        bucket.type == "aws_s3_bucket"
        bucket.expressions.bucket.constant_value == "mybucket"
        bucket.expressions.object_lock_enabled.constant_value == true

        some object_lock in input.configuration.root_module.resources
        object_lock.type == "aws_s3_bucket_object_lock_configuration"
        object_lock.expressions.bucket.constant_value == bucket.expressions.bucket.constant_value
}