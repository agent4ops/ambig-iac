package aws_s3_bucket_versioning
import future.keywords.in

default valid := false

valid { # IF THE BUCKET IS REFERRED TO BY ID
    some bucket in input.configuration.root_module.resources
    bucket.type == "aws_s3_bucket"

    some versioning in input.configuration.root_module.resources
    versioning.type == "aws_s3_bucket_versioning"

    bucket.address in versioning.expressions.bucket.references
}

valid { # IF THE BUCKET IS REFFERED TO BY NAME
    some bucket in input.configuration.root_module.resources
    bucket.type == "aws_s3_bucket"

    some versioning in input.configuration.root_module.resources
    versioning.type == "aws_s3_bucket_versioning"
    
    versioning.expressions.bucket.constant_value == bucket.expressions.bucket.constant_value
}