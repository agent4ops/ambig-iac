terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.16"
    }
  }

  required_version = ">= 1.2.0"
}
# Define the provider block for AWS
provider "aws" {
  region = "us-east-2" # Set your desired AWS region
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_network_acl" "example" {
  vpc_id = aws_vpc.example.id

  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "10.3.0.0/18"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.3.0.0/18"
    from_port  = 80
    to_port    = 80
  }
}