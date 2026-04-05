terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.75"
    }
  }

  required_version = ">= 1.9.0"
}

provider "aws" {
  region  = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

data "aws_availability_zones" "azs" {
    state = "available"
}

resource "aws_subnet" "zonea" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.azs.names[0]
}

resource "aws_subnet" "zoneb" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.azs.names[1]
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }
}

resource "aws_route_table_association" "publica" {
  subnet_id      = aws_subnet.zonea.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "publicb" {
  subnet_id      = aws_subnet.zoneb.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "allow-db-access" {
  name   = "allow-all"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = "3306"
    to_port     = "3306"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "5432"
    to_port     = "5432"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "default" {
  subnet_ids = [aws_subnet.zonea.id, aws_subnet.zoneb.id]
}