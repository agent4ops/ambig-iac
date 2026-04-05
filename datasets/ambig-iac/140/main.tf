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
name = "example"
hash_key = "TestTableHashKey"
billing_mode = "PAY_PER_REQUEST"
stream_enabled = true
stream_view_type = "NEW_AND_OLD_IMAGES"

attribute {
name = "TestTableHashKey"
type = "S"
}

replica {
region_name = "us-east-2"
}

replica {
region_name = "us-west-2"
}
}