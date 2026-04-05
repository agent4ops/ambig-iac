provider "aws" {
  region = "us-east-1"  # Replace with your desired AWS region
}

resource "aws_glacier_vault" "example" {
  name = "my-glacier-vault"
}