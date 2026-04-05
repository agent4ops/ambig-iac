package terraform.validation

default is_configuration_valid = false

default is_valid_r53_traffic_policy = false



# Validate aws_route53_zone resource
is_valid_r53_traffic_policy {
        some i
    resource := input.configuration.root_module.resources[i]
  	resource.type == "aws_route53_traffic_policy"
    resource.expressions.name
    resource.expressions.comment
    resource.expressions.document

}



# Combine all checks into a final rule
is_configuration_valid {
    is_valid_r53_traffic_policy
}



