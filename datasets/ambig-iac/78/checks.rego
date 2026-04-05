package terraform.validation

default has_s3_bucket_versioning = false
default has_dynamodb_table = false
default has_s3_bucket_server_side_encryption_configuration = false
default has_s3_bucket_public_access_block = false
default valid_configuration = false


# Check for aws_s3_bucket_versioning resource with 'bucket' and 'status'
has_s3_bucket_versioning {
    versioning := input.planned_values.root_module.resources[_]
    versioning.type == "aws_s3_bucket_versioning"
    versioning.values.versioning_configuration[_].status == "Enabled"
}

# Check for aws_dynamodb_table resource with 'name' and 'hash_key'
has_dynamodb_table {
    some i
    table := input.planned_values.root_module.resources[i]
    table.type == "aws_dynamodb_table"
    table.values.name != null
    table.values.hash_key != null
}

# Check for aws_s3_bucket_server_side_encryption_configuration resource with 'bucket', 'rule', and 'sse_algorithm'
has_s3_bucket_server_side_encryption_configuration {
    some i
    encryption := input.planned_values.root_module.resources[i]
    encryption.type == "aws_s3_bucket_server_side_encryption_configuration"
    encryption.values.rule != null
    encryption.values.rule[0].apply_server_side_encryption_by_default != null
    encryption.values.rule[0].apply_server_side_encryption_by_default[0].sse_algorithm != null
}

# Check for aws_s3_bucket_public_access_block resource with 'bucket' and boolean flags
has_s3_bucket_public_access_block {
    some i
    access_block := input.planned_values.root_module.resources[i]
    access_block.type == "aws_s3_bucket_public_access_block"
    access_block.values.block_public_acls == true
    access_block.values.block_public_policy == true
    access_block.values.ignore_public_acls == true
    access_block.values.restrict_public_buckets == true
}

# Combined validation rule
valid_configuration {
    has_s3_bucket_versioning
    has_dynamodb_table
    has_s3_bucket_server_side_encryption_configuration
    has_s3_bucket_public_access_block
}
