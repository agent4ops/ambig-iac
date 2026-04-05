package terraform.validation

default has_valid_resources = false

# Rule for aws_lightsail_distribution resource
has_valid_lightsail_distribution {
    some i
    resource := input.planned_values.root_module.resources[i]
    resource.type == "aws_lightsail_distribution"
    resource.values.name
    resource.values.bundle_id
}

# Rule for aws_lightsail_bucket resource
has_valid_lightsail_bucket {
    some i
    resource := input.planned_values.root_module.resources[i]
    resource.type == "aws_lightsail_bucket"
    resource.values.name
    resource.values.bundle_id
}

# Combined rule to ensure both conditions are met
has_valid_resources {
    has_valid_lightsail_distribution
    has_valid_lightsail_bucket
}