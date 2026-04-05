package terraform.validation

default has_valid_resources = false

# Rule for multiple aws_lightsail_disk resources
has_valid_lightsail_disks {
    count([disk | disk := input.planned_values.root_module.resources[_]; disk.type == "aws_lightsail_disk"; disk.values.name; disk.values.size_in_gb; disk.values.availability_zone]) > 0
}

# Rule for multiple aws_lightsail_disk_attachment resources
has_valid_lightsail_disk_attachments {
    count([attachment | attachment := input.planned_values.root_module.resources[_]; attachment.type == "aws_lightsail_disk_attachment"; attachment.values.disk_name; attachment.values.instance_name; attachment.values.disk_path]) > 0
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
    has_valid_lightsail_disks
    has_valid_lightsail_disk_attachments
    has_valid_lightsail_instance
}