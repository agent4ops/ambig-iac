
provider "aws" {
  region = "us-east-1"
}

terraform {
required_providers {
aws = {
source = "hashicorp/aws"
version = ">= 5.0"
}
}
}

resource "aws_dynamodb_table" "basic-dynamodb-table" {
name = "GameScores"
billing_mode = "PROVISIONED"
read_capacity = 10
write_capacity = 10
hash_key = "UserId"
range_key = "GameTitle"

attribute {
name = "UserId"
type = "S"
}

attribute {
name = "GameTitle"
type = "S"
}

tags = {
Name = "dynamodb-table-1"
Environment = "production"
}
}