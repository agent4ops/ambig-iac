package terraform.validation

default is_valid_lightsail_instance = false

is_valid_lightsail_instance {
    resource := input.planned_values.root_module.resources[_]
    resource.type == "aws_lightsail_instance"
    has_required_arguments(resource.values)
    has_valid_add_on(resource.values.add_on)
}

has_required_arguments(values) {
    values.name
    values.availability_zone
    values.blueprint_id
    values.bundle_id
}

has_valid_add_on(add_ons) {
    add_on := add_ons[_]
    add_on.type == "AutoSnapshot"
    add_on.snapshot_time
    add_on.status == "Enabled"
}