package terraform.validation

default has_valid_resources = false

# Rule for aws_lightsail_bucket resource
has_valid_lightsail_bucket {
    some i
    resource := input.planned_values.root_module.resources[i]
    resource.type == "aws_lightsail_bucket"
    resource.values.name
    resource.values.bundle_id
}

# Rule for aws_lightsail_bucket_resource_access resource
has_valid_lightsail_bucket_access {
    some i
    resource := input.planned_values.root_module.resources[i]
    resource.type == "aws_lightsail_bucket_resource_access"
    resource.values.bucket_name
    resource.values.resource_name
}

# Rule for aws_lightsail_instance resource with specific arguments
has_valid_lightsail_instance {
    some i
    resource := input.planned_values.root_module.resources[i]
    resource.type == "aws_lightsail_instance"
    resource.values.name
    resource.values.availability_zone
    resource.values.blueprint_id
    resource.values.bundle_id
}

# Combined rule to ensure all conditions are met
has_valid_resources {
    has_valid_lightsail_bucket
    has_valid_lightsail_bucket_access
    has_valid_lightsail_instance
}