provider "aws" {
  region = "us-east-1" 
}

resource "aws_cloudwatch_metric_alarm" "foobar" {
  alarm_name          = "terraform-test-foobar5"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
}

resource "aws_route53_health_check" "foo" {
  type                            = "CLOUDWATCH_METRIC"
  cloudwatch_alarm_name           = aws_cloudwatch_metric_alarm.foobar.alarm_name
  cloudwatch_alarm_region         = "us-east-1"
  insufficient_data_health_status = "Healthy"
}