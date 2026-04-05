package aws_lightsail_instance

# aws_lightsail_instance attributes - optional

default lightsail_instance_valid := false

lightsail_instance_valid {
	instance := input.configuration.root_module.resources[_]
	instance.type == "aws_lightsail_instance"
    expressions := instance.expressions

    # Validate the presence of required arguments
    expressions.name
    expressions.availability_zone
    expressions.blueprint_id
    expressions.bundle_id
    expressions.user_data
}

# You can add more specific validations here if needed.
# For example, if you want to check if the name follows a specific format,
# you could write a rule like this:

name_is_valid {
	instance := input.configuration.root_module.resources[_]
	instance.type == "aws_lightsail_instance"
	regex.match("^[a-zA-Z0-9-_]+$", instance.expressions.name.constant_value)
}