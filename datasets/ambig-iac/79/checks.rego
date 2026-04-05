package terraform.validation

default has_s3_bucket = false

default has_s3_bucket_request_payment_configuration = false

default valid_configuration = false

has_s3_bucket {
    some i
    bucket := input.planned_values.root_module.resources[i]
    bucket.type == "aws_s3_bucket"
    bucket.values.bucket == "pike-680235478471"
}

has_s3_bucket_request_payment_configuration {
    some i
    payment_config := input.planned_values.root_module.resources[i]
    payment_config.type == "aws_s3_bucket_request_payment_configuration"
    payment_config.values.bucket == "pike-680235478471"
    payment_config.values.payer == "Requester"
}

valid_configuration {
    has_s3_bucket
    has_s3_bucket_request_payment_configuration
}
