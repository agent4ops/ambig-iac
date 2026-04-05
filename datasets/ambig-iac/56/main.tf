provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "primary" {
  name = "example53.com"
}