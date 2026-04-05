package terraform.validation

default is_configuration_valid = false

default is_valid_iam_instance_profile = false

default is_valid_iam_role = false

default is_valid_iam_role_policy_attachment = false

default is_valid_eb_app = false

default is_valid_eb_env = false

default is_valid_r53_zone = false

default is_valid_r53_record = false




# Validate aws_route53_zone resource
is_valid_r53_zone {
        some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_route53_zone"
    resource.name
}

# Validate aws_route53_record
is_valid_r53_record {
        some i, j
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_route53_record"
    resource.expressions.name
    resource.expressions.type
    resource.expressions.ttl
    resource.expressions.set_identifier
    resource.expressions.weighted_routing_policy
    resource.expressions.records.references[0] == "aws_elastic_beanstalk_environment.blue.cname"
    resource.expressions.zone_id.references[0]
    
    resource2 := input.configuration.root_module.resources[j]
    resource2.type == "aws_route53_record"
    resource2.expressions.name
    resource2.expressions.type
    resource2.expressions.ttl
    resource2.expressions.records.references[0] == "aws_elastic_beanstalk_environment.green.cname"
    resource2.expressions.zone_id.references[0]
    resource2.expressions.set_identifier
    resource2.expressions.weighted_routing_policy

}


is_valid_iam_role {
        some i
    resource := input.resource_changes[i]
    resource.type == "aws_iam_role"
    contains(resource.change.after.assume_role_policy,"ec2.amazonaws.com")
}

is_valid_iam_role_policy_attachment {
                 some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_iam_role_policy_attachment"
    resource.expressions.role.references[0]
    resource.expressions.policy_arn.constant_value == "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

# Validate aws_iam_instance_profile resource
is_valid_iam_instance_profile {
                 some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_iam_instance_profile"
    resource.expressions.role.references[0]
}


# Validate aws_eb_app
is_valid_eb_app {
        some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_elastic_beanstalk_application"
    resource.expressions.name
}

# Validate aws_eb_env
is_valid_eb_env {
        some i, j
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_elastic_beanstalk_environment"
    resource.expressions.name
    resource.expressions.application.references[0]
    resource.expressions.solution_stack_name
        some a
    resource.expressions.setting[a].value.references[0]
    
    resource2 := input.configuration.root_module.resources[j]
    resource2.type == "aws_elastic_beanstalk_environment"
    resource2.expressions.name
    resource2.expressions.application.references[0]
    resource2.expressions.solution_stack_name
        some b
    resource2.expressions.setting[b].value.references[0]

}


# Combine all checks into a final rule
is_configuration_valid {
        is_valid_iam_role
    is_valid_iam_role_policy_attachment
    is_valid_iam_instance_profile
        is_valid_r53_zone
        is_valid_r53_record
    is_valid_eb_app
    is_valid_eb_env
}