provider "aws" {
  region = "us-east-1"
}

resource "aws_elastic_beanstalk_application" "tftest" {
  name        = "tf-test-name"
  description = "tf-test-desc"
}

resource "aws_elastic_beanstalk_configuration_template" "tf_template" {
  name                = "tf-test-template-config"
  application         = aws_elastic_beanstalk_application.tftest.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.0.9 running Python 3.11"
}