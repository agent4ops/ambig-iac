package terraform.validation

default valid_configuration = false
default has_s3_bucket = false
default has_s3_bucket_policy = false


# Check for if any aws_s3_bucket with "bucket"
has_s3_bucket {
    resource := input.configuration.root_module.resources[_]
    resource.type == "aws_s3_bucket"
    resource.expressions.bucket.constant_value != null
}

# Check for if any aws_s3_bucket_policy with "bucket" "policy"
has_s3_bucket_policy{
        resource := input.configuration.root_module.resources[_]
    resource.type == "aws_s3_bucket_policy"
    resource.expressions.bucket.references != null
    has_policy(resource.name)
}

has_policy(policy_name){
        resource := input.configuration.root_module.resources[_]
    resource.type == "aws_s3_bucket_policy"
    resource.name == policy_name
    resource.expressions.policy != null
}

valid_configuration{
        has_s3_bucket
    has_s3_bucket_policy
}