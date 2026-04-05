package terraform.validation

default is_valid_glacier_vault = false

# Rule to validate if there is at least one aws_glacier_vault resource with a name attribute
is_valid_glacier_vault {
    # Find a resource that is of type aws_glacier_vault
    resource := input.planned_values.root_module.resources[_]
    resource.type == "aws_glacier_vault"

    # Check that the resource has a name attribute
    has_value(resource.values.name)
}

# Helper function to check if a value exists (not null)
has_value(value) {
    not is_null(value)
}