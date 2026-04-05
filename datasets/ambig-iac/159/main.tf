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

resource "aws_vpc" "example_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.example_vpc.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_subnet" "subnet2" {
  vpc_id     = aws_vpc.example_vpc.id
  cidr_block = "10.0.2.0/24"
}
resource "aws_neptune_subnet_group" "default" {
  name       = "main"
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]

  tags = {
    Name = "My neptune subnet group"
  }
}