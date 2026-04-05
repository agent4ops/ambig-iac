package aws_s3_bucket_cors
import future.keywords.in

default valid := false

valid { # IF THE BUCKET IS REFERRED TO BY ID
    some bucket in input.configuration.root_module.resources
    bucket.type == "aws_s3_bucket"

    some cors_config in input.configuration.root_module.resources
    cors_config.type == "aws_s3_bucket_cors_configuration"
    some rule in cors_config.expressions.cors_rule
    some method1 in rule.allowed_methods.constant_value
    method1 == "POST"
    some method2 in rule.allowed_methods.constant_value
    method2 == "GET"
    some origin in rule.allowed_origins.constant_value
    origin == "https://domain.com"
    
    bucket.address in cors_config.expressions.bucket.references
}

valid { # IF THE BUCKET IS REFFERED TO BY NAME
    some bucket in input.configuration.root_module.resources
    bucket.type == "aws_s3_bucket"

    some cors_config in input.configuration.root_module.resources
    cors_config.type == "aws_s3_bucket_cors_configuration"
    some rule in cors_config.expressions.cors_rule
    some method1 in rule.allowed_methods.constant_value
    method1 == "POST"
    some method2 in rule.allowed_methods.constant_value
    method2 == "GET"
    some origin in rule.allowed_origins.constant_value
    origin == "https://domain.com"
    
    cors_config.expressions.bucket.constant_value == bucket.expressions.bucket.constant_value
}