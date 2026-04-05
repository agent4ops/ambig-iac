terraform {
required_providers {
aws = {
source = "hashicorp/aws"
version = ">= 5.0"
}
}
}

# Configure the AWS Provider
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

point_in_time_recovery {
enabled = true # Set to true to enable point-in-time recovery
}

}