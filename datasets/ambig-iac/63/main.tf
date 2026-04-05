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

variable "cluster_name" {
  type = string
  default = "test-cluster"
}

data "aws_region" "current" {}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "test_eks_1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_subnet" "test_eks_2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"

  availability_zone = data.aws_availability_zones.available.names[1]
}

resource "aws_iam_role" "example" {
  name = "${var.cluster_name}-eks"

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

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.example.name
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.example.name
}

resource "aws_eks_cluster" "example" {
  name     = var.cluster_name
  role_arn = aws_iam_role.example.arn

  vpc_config {
    subnet_ids = [ aws_subnet.test_eks_1.id, aws_subnet.test_eks_2.id ]
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_service_policy,
  ]

  # Manage kubectl configuration
  provisioner "local-exec" {
    command = "aws eks --region ${data.aws_region.current.name} update-kubeconfig --name ${self.name}"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl config unset users.${self.arn}"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "kubectl config unset clusters.${self.arn}"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "kubectl config unset contexts.${self.arn}"
  }
}
