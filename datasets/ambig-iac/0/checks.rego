package terraform.validation

default is_configuration_valid = false

default is_valid_r53_zone = false

default is_valid_cloudwatch_log_group = false

default is_valid_cloudwatch_log_resource_policy = false

default is_valid_route53_query_log = false

# Validate aws_route53_zone resource
is_valid_r53_zone {
    some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_route53_zone"
    resource.expressions.name
}

is_valid_cloudwatch_log_group {
    some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_cloudwatch_log_group"
}

is_valid_cloudwatch_log_resource_policy {
    some i
    resource := input.resource_changes[i]
    resource.type == "aws_cloudwatch_log_resource_policy"
    contains(resource.change.after.policy_document, "logs:PutLogEvents")
    contains(resource.change.after.policy_document, "logs:CreateLogStream")
    resource.change.after.policy_name
}

is_valid_route53_query_log {
    some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_route53_query_log"
    resource.expressions.zone_id.references[0] == "aws_route53_zone.primary.zone_id"
    resource.expressions.cloudwatch_log_group_arn.references[0] == "aws_cloudwatch_log_group.aws_route53_example_com.arn"
    resource.depends_on[0] == "aws_cloudwatch_log_resource_policy.route53-query-logging-policy"
}

# Combine all checks into a final rule
is_configuration_valid {
    is_valid_r53_zone
    is_valid_cloudwatch_log_group
    is_valid_cloudwatch_log_resource_policy
    is_valid_route53_query_log
}