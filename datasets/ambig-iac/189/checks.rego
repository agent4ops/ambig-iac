package aws_s3_bucket_inventory
import future.keywords.in

default valid := false

valid { # IF THE SOURCE BUCKET IS REFERRED TO BY ID
        some bucket1 in input.configuration.root_module.resources
        bucket1.type == "aws_s3_bucket"
        
    some bucket2 in input.configuration.root_module.resources
        bucket2.type == "aws_s3_bucket"
    
    not bucket1 == bucket2

        some inventory in input.configuration.root_module.resources
        inventory.type = "aws_s3_bucket_inventory"
        bucket1.address in inventory.expressions.bucket.references
    
    inventory.expressions.included_object_versions.constant_value == "Current"
    
    some schedule in inventory.expressions.schedule
    schedule.frequency.constant_value == "Weekly"
    
    some destination in inventory.expressions.destination
    some dest_bucket in destination.bucket
    bucket2.address in dest_bucket.bucket_arn.references
}

valid { # IF THE SOURCE BUCKET IS REFFERED TO BY NAME
        some bucket1 in input.configuration.root_module.resources
        bucket1.type == "aws_s3_bucket"
        
    some bucket2 in input.configuration.root_module.resources
        bucket2.type == "aws_s3_bucket"
    
    not bucket1 == bucket2

        some inventory in input.configuration.root_module.resources
        inventory.type = "aws_s3_bucket_inventory"
        bucket1.expressions.bucket.constant_value == inventory.expressions.bucket.constant_value
    
    inventory.expressions.included_object_versions.constant_value == "Current"
    
    some schedule in inventory.expressions.schedule
    schedule.frequency.constant_value == "Weekly"
    
    some destination in inventory.expressions.destination
    some dest_bucket in destination.bucket
    bucket2.address in dest_bucket.bucket_arn.references
}
