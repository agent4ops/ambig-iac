package terraform.validation


default valid_configuration = false
default has_s3_bucket = false
default has_aws_s3_bucket_acl = false
default has_aws_s3_bucket_public_access_block = false
default has_aws_s3_bucket_server_side_encryption_configuration = false

has_s3_bucket {
    resource := input.configuration.root_module.resources[_]
    resource.type == "aws_s3_bucket"    
    # resource.name == "backstage"
    # some i
    # resource.expressions.bucket.references[i] == "var.bucket_name"
}


has_aws_s3_bucket_acl{
        resource := input.configuration.root_module.resources[_]
    resource.type == "aws_s3_bucket_acl"    
    # resource.name == "backstage"
    resource.expressions.acl.constant_value != null
    
}

has_aws_s3_bucket_public_access_block{
    resource := input.configuration.root_module.resources[_]
    resource.type == "aws_s3_bucket_public_access_block"
    resource.expressions.bucket.references != null
}

has_aws_s3_bucket_server_side_encryption_configuration{
    resource := input.configuration.root_module.resources[_]
    resource.type == "aws_s3_bucket_server_side_encryption_configuration"    
    # resource.name == "backstage"
    # some i, j, k
    # resource.expressions.server_side_encryption_configuration[i].rule[j].apply_server_side_encryption_by_default[k].sse_algorithm.constant_value == "AES256" != null
    some i, j
    resource.expressions.rule[i].apply_server_side_encryption_by_default[j].sse_algorithm.constant_value == "AES256"
}

valid_configuration{
    has_s3_bucket
    has_aws_s3_bucket_acl
    has_aws_s3_bucket_public_access_block
    has_aws_s3_bucket_server_side_encryption_configuration
}
