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

resource "aws_neptune_cluster_parameter_group" "example" {
  family      = "neptune1.2"
  name        = "example"
  description = "neptune cluster parameter group"

  parameter {
    name  = "neptune_enable_audit_log"
    value = 1
  }
}

resource "aws_neptune_parameter_group" "example" {
  family = "neptune1.2"
  name   = "example"

  parameter {
    name  = "neptune_query_timeout"
    value = "25"
  }
}

resource "aws_neptune_cluster" "default" {
  cluster_identifier                  = "neptune-cluster-demo"
  engine                              = "neptune"
  backup_retention_period             = 5
  preferred_backup_window             = "07:00-09:00"
  skip_final_snapshot                 = true
  iam_database_authentication_enabled = true
  apply_immediately                   = true
  neptune_cluster_parameter_group_name = aws_neptune_cluster_parameter_group.example.id
}

resource "aws_neptune_cluster_instance" "example" {
  count              = 2
  cluster_identifier = aws_neptune_cluster.default.id
  engine             = "neptune"
  instance_class     = "db.t3.medium"
  apply_immediately  = true
  publicly_accessible = true
  neptune_parameter_group_name = aws_neptune_parameter_group.example.id
}