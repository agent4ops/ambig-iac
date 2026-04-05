package terraform.validation

default is_configuration_valid = false

default is_valid_r53_zone = false

default is_valid_r53_record = false

default is_valid_db_instance = false

default is_valid_vpc = false

default is_valid_subnet = false

default is_valid_subnet_group = false


is_valid_r53_zone {
        some i, j
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_route53_zone"
    resource.expressions.name
    resource2 := input.configuration.root_module.resources[j]
    resource2.type == "aws_route53_zone"
    resource2.expressions.name
    resource2.expressions.vpc[0].vpc_id.references[0]

}

is_valid_vpc {
		some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_vpc"
    resource.expressions.cidr_block
}

is_valid_r53_record {
        some i, j
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_route53_record"
    resource.expressions.name
    resource.expressions.type
    resource.expressions.ttl
    resource.expressions.zone_id.references[0] == "aws_route53_zone.public.zone_id"
    resource.expressions.records.references[0] == "aws_db_instance.public.address"

    resource2 := input.configuration.root_module.resources[j]
    resource2.type == "aws_route53_record"
    resource2.expressions.name
    resource2.expressions.type
    resource2.expressions.ttl
    resource2.expressions.zone_id.references[0] == "aws_route53_zone.private.zone_id"
    resource2.expressions.records.references[0] == "aws_db_instance.internal.address"
}



is_valid_subnet {
		some i, j
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_subnet"
    resource.expressions.cidr_block
    resource.expressions.availability_zone
    
    resource2 := input.configuration.root_module.resources[j]
    resource2.type == "aws_subnet"
    resource2.expressions.cidr_block
    resource2.expressions.availability_zone
    resource2.expressions.vpc_id.references[0] == resource.expressions.vpc_id.references[0]

}

is_valid_subnet_group {
		some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_db_subnet_group"
    resource.expressions.subnet_ids.references[0]
}

is_valid_db_instance {
        some i
        resource := input.configuration.root_module.resources[i]
    resource.type == "aws_db_instance"
    has_required_main_db_arguments
}

# Helper rule to check if all required arguments are present and valid
has_required_main_db_arguments {
		some i, j
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_db_instance"
    resource.expressions.db_subnet_group_name.references[0] == "aws_db_subnet_group.main.name"
    resource2 := input.configuration.root_module.resources[j]
    resource2.type == "aws_db_instance"
    resource2.expressions.publicly_accessible.constant_value == true
    # Check for allocated_storage, engine, instance_class, username, password, and skip_final_snapshot
    requirement1(resource.expressions)
    requirement1(resource2.expressions)
    # Check for instance_class validity
    requirement2(resource.expressions)
    requirement2(resource2.expressions)
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


# Combine all checks into a final rule
is_configuration_valid {
    is_valid_db_instance
    is_valid_vpc
    is_valid_subnet
    is_valid_subnet_group
    is_valid_r53_record
    is_valid_r53_zone
    
}