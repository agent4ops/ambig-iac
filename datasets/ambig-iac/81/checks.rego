package terraform.validation

default has_aws_s3_bucket_object = false

has_aws_s3_bucket_object {
    object := input.planned_values.root_module.resources[_]
    object.type == "aws_s3_bucket_object"
    object.name == "object"
    object.values.bucket == "your_bucket_name"
    object.values.key == "new_object_key"
    object.values.source == "path/to/file"
}

valid_configuration {
    has_aws_s3_bucket_object
}