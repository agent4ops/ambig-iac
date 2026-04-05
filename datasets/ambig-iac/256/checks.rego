package terraform.validation

default is_valid_db_instance = false

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
        requirement1(resource.expressions)
        requirement2(resource.expressions)
    requirement3(resource.expressions)
}

# 1, allocated_storage and engine or snapshot_identifier or replace_source_db
requirement1(expressions) {
        expressions.allocated_storage
        expressions.engine.constant_value == "mysql"
    expressions.username
        is_valid_engine(expressions.engine.constant_value)
}

requirement2(expressions) {
        expressions.instance_class
        is_valid_instance_class(expressions.instance_class.constant_value)
}

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

