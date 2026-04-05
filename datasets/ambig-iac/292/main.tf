terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.16"
    }
  }

  required_version = ">= 1.2.0"
}
# Define the provider block for AWS
provider "aws" {
  region = "us-east-2" # Set your desired AWS region
}

resource "aws_nat_gateway" "pike" {
  subnet_id         = "subnet-0562ef1d304b968f4"
  allocation_id     = "eipalloc-0047fa56c40637c3b"
  connectivity_type = "public"
  tags = {
    pike = "permissions"
  }
}