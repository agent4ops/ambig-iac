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

resource "aws_rds_cluster" "example" {
cluster_identifier = "example"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
engine = "mysql"
db_cluster_instance_class = "db.r6gd.large"
storage_type = "io1"
allocated_storage = 100
iops = 1000
master_username = "test"
master_password = "mustbeeightcharaters"
skip_final_snapshot = true
}
