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

resource "aws_vpc" "default" {
  cidr_block = "192.168.0.0/16"
}

resource "aws_vpc_dhcp_options" "default" {
  domain_name          = "windomain.local"
  domain_name_servers  = concat(["192.168.56.102"], ["8.8.8.8"])
  netbios_name_servers = ["192.168.56.102"]
}

resource "aws_vpc_dhcp_options_association" "default" {
  vpc_id          = aws_vpc.default.id
  dhcp_options_id = aws_vpc_dhcp_options.default.id
}