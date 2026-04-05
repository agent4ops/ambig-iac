terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.75"
    }
  }

  required_version = ">= 1.9.0"
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "private-us-east-1a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_subnet" "public-us-east-1a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
}

resource "aws_iam_role" "example" {
  name = "example"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.example.name
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.example.name
}

resource "aws_eks_cluster" "eks" {
  name     = "example"
  version  = "test-version"
  role_arn = aws_iam_role.example.arn

  vpc_config {
    endpoint_private_access = false
    endpoint_public_access  = true

    subnet_ids = [
      aws_subnet.private-us-east-1a.id,
      aws_subnet.public-us-east-1a.id
    ]
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy,
                aws_iam_role_policy_attachment.eks_service_policy]
}