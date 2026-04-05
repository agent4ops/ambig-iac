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

resource "aws_egress_only_internet_gateway" "pike" {
  vpc_id = "vpc-0c33dc8cd64f408c4"
  tags = {
    pike = "permissions"
  }
}