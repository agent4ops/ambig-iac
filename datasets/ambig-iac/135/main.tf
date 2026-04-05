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

resource "aws_rds_cluster" "default" {
cluster_identifier = "aurora-cluster-demo"
engine = "aurora-postgresql"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
database_name = "mydb"
master_username = "USERNAME"
master_password = "PASSWORD"
backup_retention_period = 5
preferred_backup_window = "07:00-09:00"
skip_final_snapshot = true
}