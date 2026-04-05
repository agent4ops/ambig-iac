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

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "test_eks_1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    "kubernetes.io/cluster/test" = "shared"
  }
}

resource "aws_subnet" "test_eks_2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"

  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    "kubernetes.io/cluster/test" = "shared"
  }
}

resource "aws_iam_role" "eks-cluster" {
  name = "eks-cluster-1"

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
  role       = aws_iam_role.eks-cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks-cluster.name
}


resource "aws_eks_cluster" "cluster" {
  name     = "test"
  role_arn = aws_iam_role.eks-cluster.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.test_eks_1.id,
      aws_subnet.test_eks_2.id
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_service_policy,
  ]
}

resource "aws_iam_role" "eks-fargate-profile" {
  name = "eks-fargate-profile"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks-fargate-profile" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.eks-fargate-profile.name
}

resource "aws_eks_fargate_profile" "kube-system" {
  cluster_name           = aws_eks_cluster.cluster.name
  fargate_profile_name   = "kube-system"
  pod_execution_role_arn = aws_iam_role.eks-fargate-profile.arn

  subnet_ids = [
    aws_subnet.test_eks_1.id,
    aws_subnet.test_eks_2.id
  ]

  selector {
    namespace = "kube-system"
  }

  depends_on = [ aws_iam_role_policy_attachment.eks-fargate-profile ]
}

data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.cluster.id
}

resource "null_resource" "k8s_patcher" {
  depends_on = [aws_eks_fargate_profile.kube-system]

  triggers = {
    endpoint = aws_eks_cluster.cluster.endpoint
    ca_crt   = base64decode(aws_eks_cluster.cluster.certificate_authority[0].data)
    token    = data.aws_eks_cluster_auth.eks.token
  }

  provisioner "local-exec" {
    command = <<EOH
      cat >/tmp/ca.crt <<EOF
      ${base64decode(aws_eks_cluster.cluster.certificate_authority[0].data)}
      EOF
      kubectl \
        --server="${aws_eks_cluster.cluster.endpoint}" \
        --certificate_authority=/tmp/ca.crt \
        --token="${data.aws_eks_cluster_auth.eks.token}" \
        patch deployment coredns \
        -n kube-system --type json \
        -p='[{"op": "remove", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type"}]'
      EOH
  }

  lifecycle {
    ignore_changes = [triggers]
  }
}