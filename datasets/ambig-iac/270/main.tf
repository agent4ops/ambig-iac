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

resource "aws_efs_file_system" "foo" {
  creation_token = "my-product"

  tags = {
    Name = "MyProduct"
  }
}