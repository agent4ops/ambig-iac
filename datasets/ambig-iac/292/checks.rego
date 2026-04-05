package terraform.validation

# Set default validation state
default is_valid_nat_gateway = false

# Validate aws_nat_gateway resource
is_valid_nat_gateway {
        some i
        resource := input.configuration.root_module.resources[i]
        resource.type == "aws_nat_gateway"

        # Ensure it is associated with a specified subnet
        resource.expressions.subnet_id != null

        # Ensure it uses a specific Elastic IP allocation ID
        resource.expressions.allocation_id != null

        # Check for the specific tag indicating its purpose or ownership
        resource.expressions.tags.constant_value.pike == "permissions"
}
