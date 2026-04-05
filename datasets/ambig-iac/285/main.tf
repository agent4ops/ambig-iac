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


resource "aws_vpc_dhcp_options_association" "pike" {
  dhcp_options_id = aws_vpc_dhcp_options.pike.id
  vpc_id          = "vpc-0c33dc8cd64f408c4"
}

resource "aws_vpc_dhcp_options" "pike" {
  domain_name_servers = ["8.8.8.8", "8.8.4.4"]
  tags = {
    pike = "permissions"
  }
}