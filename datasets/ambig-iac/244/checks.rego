package terraform.validation

default has_valid_lightsail_resources = false

# Rule for aws_lightsail_instance resource
has_lightsail_instance {
    some i
    resource := input.planned_values.root_module.resources[i]
    resource.type == "aws_lightsail_instance"
}

# Rule for aws_lightsail_distribution resource
has_lightsail_distribution {
    some i
    resource := input.planned_values.root_module.resources[i]
    resource.type == "aws_lightsail_distribution"
}

# Combined rule to ensure both resources are present
has_valid_lightsail_resources {
    has_lightsail_instance
    has_lightsail_distribution
}