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

resource "aws_vpc" "_" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = merge({
    "Name" = "vpc"
  })
}

resource "aws_internet_gateway" "_" {
  vpc_id = aws_vpc._.id
  tags = merge({
    "Name" = "ig"
  })
}