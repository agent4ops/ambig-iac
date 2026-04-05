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

resource "aws_lightsail_database" "test" {
  relational_database_name = "test"
  availability_zone        = "us-east-1a"
  master_database_name     = "testdatabasename"
  master_password          = "testdatabasepassword"
  master_username          = "test"
  blueprint_id             = "postgres_12"
  bundle_id                = "micro_1_0"
  apply_immediately        = true
}