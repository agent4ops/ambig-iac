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
  engine               = "mysql"
  instance_class       = "db.t3.micro"
  username             = "foo"
  manage_master_user_password = true
  master_user_secret_kms_key_id = aws_kms_key.example.key_id
}

resource "aws_kms_key" "example" {
  description = "Example KMS Key"
}