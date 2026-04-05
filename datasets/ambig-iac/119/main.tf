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

resource "aws_iam_role" "example" {
  name = "redshift_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "redshift.amazonaws.com"
        },
      },
    ],
  })
}

resource "aws_dax_cluster" "bar" {
  cluster_name       = "cluster-example"
  iam_role_arn       = aws_iam_role.example.arn
  node_type          = "dax.r4.large"
  replication_factor = 1
}