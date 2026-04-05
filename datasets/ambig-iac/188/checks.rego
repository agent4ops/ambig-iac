package s3_bucket_inventory
import future.keywords.in

default valid := false

valid {
    some bucket in input.configuration.root_module.resources
    bucket.type == "aws_s3_bucket"
    bucket.expressions.bucket.constant_value == "mybucket"
    
    some inventory in input.configuration.root_module.resources
    inventory.type == "aws_s3_bucket_inventory"
    bucket.address in inventory.expressions.bucket.references
    some freq in inventory.expressions.schedule
    freq.frequency.constant_value == "Daily"
}

valid {
    some bucket in input.configuration.root_module.resources
    bucket.type == "aws_s3_bucket"
    bucket.expressions.bucket.constant_value == "mybucket"
    
    some inventory in input.configuration.root_module.resources
    inventory.type == "aws_s3_bucket_inventory"
    inventory.expressions.bucket.constant_value == bucket.expressions.bucket.constant_value
    some freq in inventory.expressions.schedule
    freq.frequency.constant_value == "Daily"
}