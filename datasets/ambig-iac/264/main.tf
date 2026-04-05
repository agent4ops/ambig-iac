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
  allocated_storage    = 100
  engine               = "mysql"
  instance_class       = "db.t3.micro"
  username             = "foo"
  password             = "foobarbaz"
  storage_type        = "io1"
}