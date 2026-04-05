provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "example" {
  name = "test"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}


resource "aws_dax_cluster" "bar" {
  cluster_name       = "cluster-example"
  iam_role_arn       = aws_iam_role.example.arn
  node_type          = "dax.r4.large"
  replication_factor = 1
}