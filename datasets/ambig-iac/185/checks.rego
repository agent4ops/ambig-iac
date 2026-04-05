package s3_bucket_acl
import future.keywords.in

default valid := false

valid {
    some bucket in input.configuration.root_module.resources
    bucket.type == "aws_s3_bucket"
    bucket.expressions.bucket.constant_value == "mybucket"
    
    some ownership_controls in input.configuration.root_module.resources
    ownership_controls.type == "aws_s3_bucket_ownership_controls"
    bucket.address in ownership_controls.expressions.bucket.references
    some rule in ownership_controls.expressions.rule
    rule.object_ownership.constant_value == "BucketOwnerPreferred"

    some acl in input.configuration.root_module.resources
    acl.type == "aws_s3_bucket_acl"
    bucket.address in acl.expressions.bucket.references
    acl.expressions.acl.constant_value == "private"
    ownership_controls.address in acl.depends_on
}