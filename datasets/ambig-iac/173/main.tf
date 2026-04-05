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
  cluster_identifier = "default"
  database_name      = "default"
  master_username    = "exampleuser"
  master_password    = "Mustbe8characters"
  node_type          = "ra3.xlplus"
  cluster_type       = "single-node"
}

resource "aws_sns_topic" "default" {
  name = "redshift-events"
}

resource "aws_redshift_event_subscription" "default" {
  name          = "redshift-event-sub"
  sns_topic_arn = aws_sns_topic.default.arn

  source_type = "cluster"
  source_ids  = [aws_redshift_cluster.example.id]

  severity = "INFO"

  event_categories = [
    "configuration",
    "management",
    "monitoring",
    "security",
  ]

  tags = {
    Name = "default"
  }
}