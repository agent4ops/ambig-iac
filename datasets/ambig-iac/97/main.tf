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

resource "aws_iam_role" "redshift_role" {
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

resource "aws_iam_role_policy_attachment" "redshift_s3_read_only" {
  role       = aws_iam_role.redshift_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_redshift_cluster" "example" {
  cluster_identifier = "tf-redshift-cluster"
  database_name      = "mydb"
  master_username    = "foo"
  master_password    = "Mustbe8characters"
  node_type          = "dc2.large"
  cluster_type       = "single-node"

  depends_on = [aws_iam_role.redshift_role]
}

resource "aws_redshift_cluster_iam_roles" "example" {
  cluster_identifier = aws_redshift_cluster.example.id
  iam_role_arns      = [aws_iam_role.redshift_role.arn]
}