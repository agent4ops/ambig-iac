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
    resource.values.blueprint_id == "postgres_12"
    resource.values.bundle_id
    resource.values.apply_immediately == true
}