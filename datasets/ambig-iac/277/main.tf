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

resource "aws_vpc" "dgraph" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  instance_tenancy     = "dedicated"

  # For enabling assignment of private dns addresses within AWS.
  enable_dns_hostnames = true

  tags = {
    Name = "var.name"
  }
}

resource "aws_internet_gateway" "dgraph_gw" {
  vpc_id = aws_vpc.dgraph.id

  tags = {
    Name = "var.name"
  }
}

resource "aws_route_table" "dgraph_igw" {
  vpc_id = aws_vpc.dgraph.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dgraph_gw.id
  }

  tags = {
    Name = "var.name"
  }
}