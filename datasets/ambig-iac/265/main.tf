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
  password             = "foobarbaz"
  s3_import {
    bucket_name           = "mybucket"
    ingestion_role        = "arn:aws:iam::1234567890:role/role-xtrabackup-rds-restore"
    source_engine         = "mysql"
    source_engine_version = "5.6"
  }
}