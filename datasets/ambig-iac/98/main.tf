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
  cluster_type       = "multi-node"
  number_of_nodes    = 2

  database_name = "mydb"
  master_username = "foo"
  master_password = "Mustbe8characters"

  skip_final_snapshot = true
}

resource "aws_redshift_resource_policy" "example" {
  resource_arn = aws_redshift_cluster.example.cluster_namespace_arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::12345678901:root"
      }
      Action   = "redshift:CreateInboundIntegration"
      Resource = aws_redshift_cluster.example.cluster_namespace_arn
      Sid      = ""
    }]
  })
}