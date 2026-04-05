package terraform.validation

default has_valid_lightsail_instance = false

# Main rule to check for a valid aws_lightsail_instance
has_valid_lightsail_instance {
    resource := input.planned_values.root_module.resources[_]
    resource.type == "aws_lightsail_instance"
    resource.values.name
    resource.values.availability_zone
    resource.values.blueprint_id == "wordpress"
    resource.values.bundle_id
}