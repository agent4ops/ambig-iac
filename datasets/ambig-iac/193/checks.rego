package aws_s3_bucket_cors
import future.keywords.in

default valid := false

valid { # IF THE BUCKET IS REFERRED TO BY ID
	some bucket in input.configuration.root_module.resources
    bucket.type == "aws_s3_bucket"

	some cors_config in input.configuration.root_module.resources
    cors_config.type == "aws_s3_bucket_cors_configuration"
    
    bucket.address in cors_config.expressions.bucket.references
}

valid { # IF THE BUCKET IS REFFERED TO BY NAME
	some bucket in input.configuration.root_module.resources
    bucket.type == "aws_s3_bucket"

	some cors_config in input.configuration.root_module.resources
    cors_config.type == "aws_s3_bucket_cors_configuration"
    
	cors_config.expressions.bucket.constant_value == bucket.expressions.bucket.constant_value
}