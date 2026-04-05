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

resource "aws_vpc" "vpc" {
cidr_block = "192.168.0.0/22"
}

resource "aws_db_instance" "default" {
allocated_storage = 10
db_name = "mydb"
engine = "mysql"
instance_class = "db.t3.micro"
username = "USERNAME"
password = "PASSWORD"
parameter_group_name = "default.mysql5.7"
skip_final_snapshot = true
}