provider "aws" {
  region = "us-west-2"
}

resource "aws_kinesis_analytics_application" "test_application" {
  name = "kinesis-analytics-application-test"
}