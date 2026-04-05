# Define the provider block for AWS
provider "aws" {
  region = "us-east-2" # Set your desired AWS region
}

resource "aws_egress_only_internet_gateway" "pike" {
  vpc_id = "vpc-0c33dc8cd64f408c4"
  tags = {
    pike = "permissions"
  }
}