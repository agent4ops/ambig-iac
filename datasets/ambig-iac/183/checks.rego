package aws_s3
import future.keywords.in

default valid := false

valid {
    some bucket in input.configuration.root_module.resources
    bucket.type == "aws_s3_bucket"
}