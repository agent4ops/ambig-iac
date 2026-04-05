package terraform.validation

default has_required_resources = false

# Rule for aws_lightsail_instance resource
has_lightsail_instance {
    some i
    resource := input.planned_values.root_module.resources[i]
    resource.type == "aws_lightsail_instance"
    resource.values.name
    resource.values.availability_zone
    resource.values.blueprint_id
    resource.values.bundle_id
}

# Rule for aws_lightsail_static_ip resource
has_lightsail_static_ip {
    some i
    resource := input.planned_values.root_module.resources[i]
    resource.type == "aws_lightsail_static_ip"
    resource.values.name
}

# Rule for aws_lightsail_static_ip_attachment resource considering expressions
has_lightsail_static_ip_attachment {
    some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_lightsail_static_ip_attachment"
    static_ip_name_exists(resource)
    instance_name_exists(resource)
}

static_ip_name_exists(resource) {
    resource.expressions.static_ip_name.references[_]
}

instance_name_exists(resource) {
    resource.expressions.instance_name.references[_]
}

# Combined rule to ensure all conditions are met
has_required_resources {
    has_lightsail_instance
    has_lightsail_static_ip
    has_lightsail_static_ip_attachment
}