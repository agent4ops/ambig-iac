package terraform.validation

default is_configuration_valid = false

default is_valid_eb_app = false

default is_valid_iam_role = false



is_valid_eb_app {
        some i 
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_elastic_beanstalk_application"
    resource.expressions.name
    resource.expressions.appversion_lifecycle[0].service_role.references[0]
    resource.expressions.appversion_lifecycle[0].max_age_in_days.constant_value == 5

}
is_valid_iam_role {
        some i
    resource := input.resource_changes[i]
    resource.type == "aws_iam_role"
    contains(resource.change.after.assume_role_policy,"elasticbeanstalk.amazonaws.com")
}


is_configuration_valid {
    is_valid_eb_app
    is_valid_iam_role
}