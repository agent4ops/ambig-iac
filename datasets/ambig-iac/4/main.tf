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
  region = "us-east-1" 
}

# Create a VPC for internal resources
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/24"
}


# RDS instances
resource "aws_db_instance" "internal" {
  # Internal DB configuration
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = "db.t3.micro"
  identifier =  "internal"
  username             = "user"
  password             = "password"
  db_subnet_group_name = aws_db_subnet_group.main.name
  skip_final_snapshot  = true
}

resource "aws_db_instance" "public" {
  # Public DB configuration
  publicly_accessible  = true
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = "db.t3.micro"
  identifier = "public"
  username             = "user"
  password             = "password"
  skip_final_snapshot  = true
}

resource "aws_db_subnet_group" "main" {
  name       = "mydb-subnet-group"
  subnet_ids = [aws_subnet.maina.id, aws_subnet.mainb.id]
}

data "aws_availability_zones" "available" {}

# Subnet for RDS
resource "aws_subnet" "maina" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.0.0/25"
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_subnet" "mainb" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.0.128/25"
  availability_zone = data.aws_availability_zones.available.names[1]
}

# Route 53 Public Hosted Zone for external users
resource "aws_route53_zone" "public" {
  name = "example53.com"
}

# Route 53 Private Hosted Zone for internal users
resource "aws_route53_zone" "private" {
  name = "example53.com"
  vpc {
    vpc_id = aws_vpc.main.id
  }
}

# Route 53 Record for Public DB (External Endpoint)
resource "aws_route53_record" "public_db" {
  zone_id = aws_route53_zone.public.zone_id
  name    = "public-db.example.com"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_db_instance.public.address]
}

# Route 53 Record for Internal DB (Internal Endpoint)
resource "aws_route53_record" "internal_db" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "internal-db.example.com"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_db_instance.internal.address]
}