package terraform.validation

default is_configuration_valid = false

# Rule to check if a valid aws_db_instance exists
is_valid_db_instance {
    resource := input.configuration.root_module.resources[_]
    resource.type == "aws_db_instance"
    has_required_db_arguments
}

# Helper rule to check if all required arguments are present and valid
has_required_db_arguments {
    resource := input.configuration.root_module.resources[_]
    resource.type == "aws_db_instance"
    # Check for allocated_storage, engine, instance_class, username, and skip_final_snapshot
    requirement1(resource.expressions)
    # Check for instance_class validity
    requirement2(resource.expressions)
    requirement3(resource.expressions)
    
    check_identifier_contains_random_id(resource.expressions)
    check_password_contains_random_password(resource.expressions)
}

# 1, allocated_storage and engine or snapshot_identifier or replace_source_db
requirement1(expressions) {
    expressions.allocated_storage.constant_value == 20
    expressions.engine.constant_value == "mysql"
    expressions.username != null
    is_valid_engine(expressions.engine.constant_value)
}

requirement1(expressions) {
    expressions.snapshot_identifier
}

requirement1(expressions) {
    expressions.replicate_source_db
}

# Check for instance_class validity
requirement2(expressions) {
    expressions.instance_class
    is_valid_instance_class(expressions.instance_class.constant_value)
}

# Check for password existence and its source
requirement3(expressions) {
    expressions.password
}

requirement3(expressions) {
    expressions.manage_master_user_password
}

requirement3(expressions) {
    expressions.snapshot_identifier
}

requirement3(expressions) {
    expressions.replicate_source_db
}

requirement3(expressions) {
    expressions.manage_master_user_password
}

# Check that the identifier references contain "random_id"
check_identifier_contains_random_id(expressions) {
    # Ensure the first reference in the identifier expression contains "random_id"
    contains(expressions.identifier.references[0], "random_id")
}

# Check that the password references contain "random_password"
check_password_contains_random_password(expressions) {
    # Ensure the first reference in the password expression contains "random_password"
    contains(expressions.password.references[0], "random_password")
}

# Helper rule to validate engine value
is_valid_engine(engine) {
        engine_set := {
        "mysql",
        "postgres",
        "mariadb",
        "oracle-se",
        "oracle-se1",
        "oracle-se2",
        "oracle-ee",
        "sqlserver-ee",
        "sqlserver-se",
        "sqlserver-ex",
        "sqlserver-web"
    }
        engine_set[engine]
}

# Helper rule to validate instance class type
is_valid_instance_class(instance_class) {
        instance_class_starts_with(instance_class, "db.")
}

# Helper rule to check prefix of instance class
instance_class_starts_with(instance_class, prefix) {
        startswith(instance_class, prefix)
}



# Rule to check if exactly one random_id resource exists
has_one_random_id {
    resource := input.configuration.root_module.resources[_]
    resource.type == "random_id"
}

# Rule to check if exactly one random_password resource exists
has_one_random_password {
    resource := input.configuration.root_module.resources[_]
    resource.type == "random_password"
}

# Combine all checks into a final rule
is_configuration_valid {
    is_valid_db_instance
    has_one_random_id
    has_one_random_password
}
