
provider "aws" {
  region = "us-east-1"
}

terraform {
required_providers {
aws = {
source = "hashicorp/aws"
version = ">= 5.0"
}
}
}

resource "aws_vpc" "vpc" {
cidr_block = "192.168.0.0/22"
}


resource "aws_subnet" "example1" {
cidr_block = "192.168.0.0/24"
vpc_id = aws_vpc.vpc.id
}

resource "aws_subnet" "example2" {
cidr_block = "192.168.1.0/24"
vpc_id = aws_vpc.vpc.id
}

resource "aws_dax_subnet_group" "example" {
name = "example"
subnet_ids = [aws_subnet.example1.id, aws_subnet.example2.id]
}