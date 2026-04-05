terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_lightsail_certificate" "test" {
  name                      = "test"
  domain_name               = "testdomain.com"
  subject_alternative_names = ["www.testdomain.com"]
}