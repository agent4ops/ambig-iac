provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "subnet_east_1a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "subnet-east-1a"
  }
}

resource "aws_subnet" "subnet_east_1b" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "subnet-east-1b"
  }
}

resource "aws_redshift_subnet_group" "redshift_subnet_group" {
  name       = "my-redshift-subnet-group"
  subnet_ids = [aws_subnet.subnet_east_1a.id, aws_subnet.subnet_east_1b.id]

  tags = {
    Name = "my-redshift-subnet-group"
  }
}