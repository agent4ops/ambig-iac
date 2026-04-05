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

resource "aws_s3_bucket" "bucket" {
  bucket_prefix = "my-bucket-"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Subnets
resource "aws_subnet" "first" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
}

resource "aws_subnet" "second" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"

  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[1]
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "first" {
  subnet_id      = aws_subnet.first.id
  route_table_id = aws_route_table.main.id
}

resource "aws_route_table_association" "second" {
  subnet_id      = aws_subnet.second.id
  route_table_id = aws_route_table.main.id
}

resource "aws_security_group" "first" {
  name        = "test-security-group"
  description = "Allow traffic for Elasticsearch"
  vpc_id      = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "ingress1" {
  security_group_id = aws_security_group.first.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 80
  ip_protocol = "tcp"
  to_port = 80
}

resource "aws_vpc_security_group_ingress_rule" "ingress2" {
  security_group_id = aws_security_group.first.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 443
  ip_protocol = "tcp"
  to_port = 443
}

resource "aws_vpc_security_group_ingress_rule" "ingress3" {
  security_group_id = aws_security_group.first.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 9200
  ip_protocol = "tcp"
  to_port = 9200
}

resource "aws_vpc_security_group_egress_rule" "egress1" {
  security_group_id = aws_security_group.first.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

data "aws_iam_policy_document" "firehose_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "firehose_role" {
  name               = "firehose_test_role"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json
}

resource "aws_iam_role_policy" "firehose-opensearch" {
  name   = "opensearch"
  role   = aws_iam_role.firehose_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "es:*"
      ],
      "Resource": [
        "${aws_opensearch_domain.test_cluster.arn}",
        "${aws_opensearch_domain.test_cluster.arn}/*"
      ]
        },
        {
          "Effect": "Allow",
          "Action": [
            "ec2:DescribeVpcs",
            "ec2:DescribeVpcAttribute",
            "ec2:DescribeSubnets",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeNetworkInterfaces",
            "ec2:CreateNetworkInterface",
            "ec2:CreateNetworkInterfacePermission",
            "ec2:DeleteNetworkInterface"
          ],
          "Resource": [
            "*"
          ]
        }
  ]
}
EOF
}

resource "aws_opensearch_domain" "test_cluster" {
  domain_name = "es-test"

  cluster_config {
    instance_count         = 2
    zone_awareness_enabled = true
    instance_type          = "m4.large.search"
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
  }

  vpc_options {
    security_group_ids = [aws_security_group.first.id]
    subnet_ids         = [aws_subnet.first.id, aws_subnet.second.id]
  }
}

resource "aws_kinesis_firehose_delivery_stream" "test" {
  depends_on = [aws_iam_role_policy.firehose-opensearch]

  name        = "terraform-kinesis-firehose-os"
  destination = "opensearch"

  opensearch_configuration {
    domain_arn = aws_opensearch_domain.test_cluster.arn
    role_arn   = aws_iam_role.firehose_role.arn
    index_name = "test"

    s3_configuration {
      role_arn   = aws_iam_role.firehose_role.arn
      bucket_arn = aws_s3_bucket.bucket.arn
    }

    vpc_config {
      subnet_ids         = [aws_subnet.first.id, aws_subnet.second.id]
      security_group_ids = [aws_security_group.first.id]
      role_arn           = aws_iam_role.firehose_role.arn
    }
  }
}