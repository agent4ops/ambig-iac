package terraform.validation

default is_configuration_valid = false

default is_valid_r53_zone = false

default is_valid_r53_record_us = false

default is_valid_r53_record_eu = false

default is_valid_r53_record_ap = false

default is_valid_db_instance_main = false

default is_valid_db_instance_replicaus = false

default is_valid_db_instance_replicaeu = false

default is_valid_db_instance_replicaap = false


# Validate aws_route53_zone resource
is_valid_r53_zone {
        some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_route53_zone"
    resource.name == "main"
    resource.provider_config_key == "aws.main"


}

# Validate aws_route53_record
is_valid_r53_record_us {
        some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_route53_record"
    resource.provider_config_key == "aws.us_east"
    resource.expressions.name
    resource.expressions.weighted_routing_policy[0].weight
    resource.expressions.type
    resource.expressions.ttl
    resource.expressions.records.references[0] == "aws_db_instance.replica_us_east.endpoint"
    resource.expressions.set_identifier
    resource.expressions.zone_id.references[0] == "aws_route53_zone.main.zone_id"
}

is_valid_r53_record_eu {
        some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_route53_record"
    resource.provider_config_key == "aws.eu_central"
    resource.expressions.name
    resource.expressions.weighted_routing_policy[0].weight
    resource.expressions.type
    resource.expressions.ttl
    resource.expressions.records.references[0] == "aws_db_instance.replica_eu_central.endpoint"
    resource.expressions.set_identifier
    resource.expressions.zone_id.references[0] == "aws_route53_zone.main.zone_id"
   }
   
is_valid_r53_record_ap {
        some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_route53_record"
    resource.provider_config_key == "aws.ap_southeast"
    resource.expressions.name
    resource.expressions.weighted_routing_policy[0].weight
    resource.expressions.type
    resource.expressions.ttl
    resource.expressions.records.references[0] == "aws_db_instance.replica_ap_southeast.endpoint"
    resource.expressions.set_identifier
    resource.expressions.zone_id.references[0] == "aws_route53_zone.main.zone_id"
   }

# Rule to check if a valid aws_db_instance exists
is_valid_db_instance_main {
    resource := input.configuration.root_module.resources[_]
    resource.type == "aws_db_instance"
    resource.provider_config_key == "aws.main"
    has_required_main_db_arguments
}

is_valid_db_instance_replicaus {
    resource := input.configuration.root_module.resources[_]
    resource.type == "aws_db_instance"
    has_required_db_replicaus_arguments
}

is_valid_db_instance_replicaeu {
    resource := input.configuration.root_module.resources[_]
    resource.type == "aws_db_instance"
    has_required_db_replicaeu_arguments
}

is_valid_db_instance_replicaap {
    resource := input.configuration.root_module.resources[_]
    resource.type == "aws_db_instance"
    has_required_db_replicaap_arguments
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

has_required_db_replicaus_arguments {
    resource := input.configuration.root_module.resources[_]
    resource.type == "aws_db_instance"
    resource.name == "replica_us_east"
    resource.provider_config_key == "aws.us_east"
    resource.expressions.replicate_source_db.references[0] == "aws_db_instance.primary.arn"
    is_valid_instance_class(resource.expressions.instance_class.constant_value)
    resource.expressions.skip_final_snapshot
}

has_required_db_replicaeu_arguments {
    resource := input.configuration.root_module.resources[_]
    resource.type == "aws_db_instance"
    resource.name == "replica_eu_central"
    resource.provider_config_key == "aws.eu_central"
    resource.expressions.replicate_source_db.references[0] == "aws_db_instance.primary.arn"
    is_valid_instance_class(resource.expressions.instance_class.constant_value)
    resource.expressions.skip_final_snapshot
}

has_required_db_replicaap_arguments {
    resource := input.configuration.root_module.resources[_]
    resource.type == "aws_db_instance"
    resource.name == "replica_ap_southeast"
    resource.provider_config_key == "aws.ap_southeast"
    resource.expressions.replicate_source_db.references[0] == "aws_db_instance.primary.arn"
    is_valid_instance_class(resource.expressions.instance_class.constant_value)
    resource.expressions.skip_final_snapshot
}


# Combine all checks into a final rule
is_configuration_valid {
    is_valid_r53_zone
    is_valid_r53_record_us
    is_valid_r53_record_eu
    is_valid_r53_record_ap
    is_valid_db_instance_main
    is_valid_db_instance_replicaus
    is_valid_db_instance_replicaeu
    is_valid_db_instance_replicaap
}


