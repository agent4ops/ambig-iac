package terraform.validation

default is_configuration_valid = false

default is_valid_r53_zone = false

default is_valid_r53_record_primary = false

default is_valid_r53_record_secondary = false

default is_valid_db_instance_main = false

default is_valid_db_instance_replica1 = false

default is_valid_db_instance_replica2 = false


# Validate aws_route53_zone resource
is_valid_r53_zone {
        some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_route53_zone"
    resource.name == "main"

}

# Validate aws_route53_record
is_valid_r53_record_primary {
        some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_route53_record"
    resource.expressions.name
    resource.expressions.weighted_routing_policy[0].weight
    resource.expressions.type.constant_value == "CNAME"
    resource.expressions.ttl
    resource.expressions.records.references[0] == "aws_db_instance.replica_1.endpoint"
    resource.expressions.set_identifier
    resource.expressions.zone_id.references[0] == "aws_route53_zone.main.zone_id"
}

is_valid_r53_record_secondary {
        some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_route53_record"
    resource.expressions.name
    resource.expressions.weighted_routing_policy[0].weight
    resource.expressions.type.constant_value == "CNAME"
    resource.expressions.ttl
    resource.expressions.records.references[0] == "aws_db_instance.replica_2.endpoint"
    resource.expressions.set_identifier
    resource.expressions.zone_id.references[0] == "aws_route53_zone.main.zone_id"
   }

# Rule to check if a valid aws_db_instance exists
is_valid_db_instance_main {
    resource := input.configuration.root_module.resources[_]
    resource.type == "aws_db_instance"
    has_required_main_db_arguments
}

is_valid_db_instance_replica1 {
    resource := input.configuration.root_module.resources[_]
    resource.type == "aws_db_instance"
    has_required_db_replica1_arguments
}

is_valid_db_instance_replica2 {
    resource := input.configuration.root_module.resources[_]
    resource.type == "aws_db_instance"
    has_required_db_replica2_arguments
}

# Helper rule to check if all required arguments are present and valid
has_required_main_db_arguments {
    resource := input.configuration.root_module.resources[_]
    resource.type == "aws_db_instance"
    # Check for allocated_storage, engine, instance_class, username, password, and skip_final_snapshot
    requirement1(resource.expressions)
    # Check for instance_class validity
    requirement2(resource.expressions)
}



# 1, allocated_storage and engine or snapshot_identifier or replace_source_db
requirement1(expressions) {
    expressions.allocated_storage
    expressions.engine
    expressions.username
    expressions.password
    is_valid_engine(expressions.engine.constant_value)
}

requirement1(expressions) {
    expressions.snapshot_identifier
}

# Check for instance_class validity
requirement2(expressions) {
    expressions.instance_class
    is_valid_instance_class(expressions.instance_class.constant_value)
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

has_required_db_replica1_arguments {
    resource := input.configuration.root_module.resources[_]
    resource.type == "aws_db_instance"
    resource.name == "replica_1"
    resource.expressions.replicate_source_db.references[0] == "aws_db_instance.primary.identifier"
    is_valid_instance_class(resource.expressions.instance_class.constant_value)
    resource.expressions.skip_final_snapshot
}

has_required_db_replica2_arguments {
    resource := input.configuration.root_module.resources[_]
    resource.type == "aws_db_instance"
    resource.name == "replica_2"
    resource.expressions.replicate_source_db.references[0] == "aws_db_instance.primary.identifier"
    is_valid_instance_class(resource.expressions.instance_class.constant_value)
    resource.expressions.skip_final_snapshot
}


# Combine all checks into a final rule
is_configuration_valid {
    is_valid_r53_zone
    is_valid_r53_record_primary
    is_valid_r53_record_secondary
    is_valid_db_instance_main
    is_valid_db_instance_replica1
    is_valid_db_instance_replica2

}



