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

resource "aws_db_instance" "default" {
allocated_storage = 10
db_name = "mydb"
engine = "postgres"
instance_class = "db.t3.micro"
username = "USERNAME"
password = "PASSWORD"
skip_final_snapshot = true
}