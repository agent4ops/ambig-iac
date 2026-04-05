package aws_s3_bucket_public_access_block

import future.keywords.in

default valid := false

valid { # IF THE BUCKET IS REFERRED TO BY ID
        some bucket in input.configuration.root_module.resources
        bucket.type == "aws_s3_bucket"

        some public_access in input.configuration.root_module.resources
        public_access.type == "aws_s3_bucket_public_access_block"

        bucket.address in public_access.expressions.bucket.references
}

valid { # IF THE BUCKET IS REFFERED TO BY NAME
        some bucket in input.configuration.root_module.resources
        bucket.type == "aws_s3_bucket"

        some public_access in input.configuration.root_module.resources
        public_access.type == "aws_s3_bucket_public_access_block"

        public_access.expressions.bucket.constant_value == bucket.expressions.bucket.constant_value
}