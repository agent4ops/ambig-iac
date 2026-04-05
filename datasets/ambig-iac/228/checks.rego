package terraform.validation

default is_valid_lightsail_instance = false

is_valid_lightsail_instance {
    resource := input.planned_values.root_module.resources[_]
    resource.type == "aws_lightsail_instance"
    has_required_arguments(resource.values)
}

has_required_arguments(values) {
    values.name
    values.availability_zone
    values.blueprint_id
    values.bundle_id
}