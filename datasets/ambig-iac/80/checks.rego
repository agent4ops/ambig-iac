package terraform.validation

default has_s3_bucket = false

default has_s3_bucket_public_access_block = false

default valid_configuration = false

has_s3_bucket {
    resource := input.planned_values.root_module.resources[_]
    resource.type == "aws_s3_bucket"
    resource.values.bucket == "pike-680235478471"
}

has_s3_bucket_public_access_block {
    some i
    resource := input.planned_values.root_module.resources[i]
    resource.type == "aws_s3_bucket_public_access_block"
    resource.values.bucket ==  "pike-680235478471"
    resource.values.block_public_acls == true
    resource.values.block_public_policy == true
    resource.values.ignore_public_acls == true
    resource.values.restrict_public_buckets == true

}


valid_configuration {
    has_s3_bucket
    has_s3_bucket_public_access_block
}