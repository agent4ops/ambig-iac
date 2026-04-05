package terraform.validation

default has_valid_lightsail_database = false

# Rule for aws_lightsail_database resource with specific arguments
has_valid_lightsail_database {
    some i
    resource := input.planned_values.root_module.resources[i]
    resource.type == "aws_lightsail_database"
    resource.values.relational_database_name
    resource.values.master_database_name
    resource.values.master_password
    resource.values.master_username
    resource.values.bundle_id
    resource.values.preferred_backup_window == "16:00-16:30"
    resource.values.preferred_maintenance_window == "Tue:17:00-Tue:17:30"
    
}