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

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "example_igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "example_public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "10.0.1.0/24"
    gateway_id = aws_internet_gateway.example_igw.id
  }
}