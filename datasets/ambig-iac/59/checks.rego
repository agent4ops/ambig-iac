package terraform.validation

default is_configuration_valid = false

default is_valid_r53_health_check = false

default is_valid_cloud_watch_alarm = false


# Validate aws_route53_health_check
is_valid_r53_health_check {
        some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_route53_health_check"
    resource.expressions.type.constant_value == "CLOUDWATCH_METRIC"
    resource.expressions.cloudwatch_alarm_name.references[0] == "aws_cloudwatch_metric_alarm.foobar.alarm_name"
    resource.expressions.cloudwatch_alarm_region.constant_value == "us-east-1"
    resource.expressions.insufficient_data_health_status.constant_value = "Healthy"
}

is_valid_cloud_watch_alarm {
        some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_cloudwatch_metric_alarm"
    resource.expressions.alarm_name
    resource.expressions.comparison_operator.constant_value == "GreaterThanOrEqualToThreshold"
    resource.expressions.evaluation_periods
    resource.expressions.metric_name.constant_value == "CPUUtilization"
    resource.expressions.namespace.constant_value == "AWS/EC2"
    resource.expressions.period.constant_value == "120"
    resource.expressions.statistic.constant_value == "Average"
    resource.expressions.threshold
}
 


# Combine all checks into a final rule
is_configuration_valid {
    is_valid_r53_health_check
    is_valid_cloud_watch_alarm
}



