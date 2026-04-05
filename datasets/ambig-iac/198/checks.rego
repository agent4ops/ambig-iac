package aws_s3_bucket_payment_config
import future.keywords.in

default valid := false

valid { # IF THE BUCKET IS REFERRED TO BY ID
        some bucket in input.configuration.root_module.resources
        bucket.type == "aws_s3_bucket"

        some payment_config in input.configuration.root_module.resources
        payment_config.type == "aws_s3_bucket_request_payment_configuration"

        bucket.address in payment_config.expressions.bucket.references
}

valid { # IF THE BUCKET IS REFFERED TO BY NAME
        some bucket in input.configuration.root_module.resources
        bucket.type == "aws_s3_bucket"

        some payment_config in input.configuration.root_module.resources
        payment_config.type == "aws_s3_bucket_request_payment_configuration"

        payment_config.expressions.bucket.constant_value == bucket.expressions.bucket.constant_value
}