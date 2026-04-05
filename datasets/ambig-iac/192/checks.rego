package aws_s3_bucket_sse
import future.keywords.in

default valid := false

valid { # IF THE BUCKET IS REFERRED TO BY ID
        some bucket in input.configuration.root_module.resources
        bucket.type == "aws_s3_bucket"

        some kms_key in input.configuration.root_module.resources
        kms_key.type == "aws_kms_key"

        some sse in input.configuration.root_module.resources
        sse.type = "aws_s3_bucket_server_side_encryption_configuration"
        bucket.address in sse.expressions.bucket.references
        some rule in sse.expressions.rule
        some rule_args in rule.apply_server_side_encryption_by_default
        kms_key.address in rule_args.kms_master_key_id.references
    rule_args.sse_algorithm.constant_value == "aws:kms"
}

valid { # IF THE BUCKET IS REFFERED TO BY NAME
        some bucket in input.configuration.root_module.resources
        bucket.type == "aws_s3_bucket"

        some kms_key in input.configuration.root_module.resources
        kms_key.type == "aws_kms_key"

        some sse in input.configuration.root_module.resources
        sse.type = "aws_s3_bucket_server_side_encryption_configuration"
        bucket.expressions.bucket.constant_value == sse.expressions.bucket.constant_value
        some rule in sse.expressions.rule
        some rule_args in rule.apply_server_side_encryption_by_default
        kms_key.address in rule_args.kms_master_key_id.references
    rule_args.sse_algorithm.constant_value == "aws:kms"
    
}