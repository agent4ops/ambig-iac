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

resource "aws_redshift_cluster" "example" {
  cluster_identifier = "redshift-cluster-1"
  node_type          = "dc2.large"
  number_of_nodes    = 1

  database_name = "mydb"
  master_username = "foo"
  master_password = "Mustbe8characters"

  skip_final_snapshot = true
}

resource "aws_redshift_snapshot_schedule" "default" {
  identifier = "tf-redshift-snapshot-schedule"
  definitions = [
    "rate(12 hours)",
  ]
}

resource "aws_redshift_snapshot_schedule_association" "default" {
  cluster_identifier  = aws_redshift_cluster.example.id
  schedule_identifier = aws_redshift_snapshot_schedule.default.id
}