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

resource "aws_dynamodb_table" "example" {
name = "your-dynamodb-table-name"
billing_mode = "PAY_PER_REQUEST" # Or "PROVISIONED" if you prefer provisioned capacity
hash_key = "id"
attribute {
name = "id"
type = "S"
}

# Define other table settings as needed

server_side_encryption {
enabled = true
}
}