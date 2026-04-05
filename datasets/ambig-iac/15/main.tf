provider "aws" {
  region = "us-east-1"
}

resource "aws_elastic_beanstalk_application" "tftest" {
  name        = "tf-test-name"
  description = "tf-test-desc"
}