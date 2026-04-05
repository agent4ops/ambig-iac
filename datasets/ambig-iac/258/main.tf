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

resource "aws_db_instance" "default" {
  allocated_storage    = 20
  engine               = "postgres"
  instance_class       = "db.z1d.micro"
  username             = "foo"
  password             = "foobarbaz"
}