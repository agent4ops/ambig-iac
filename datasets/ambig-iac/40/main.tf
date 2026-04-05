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
  region  = "us-east-1"
}

resource "aws_s3_bucket" "januarythird" {
  bucket = "januarythird"
}

resource "aws_elasticsearch_domain" "test_cluster" {
  domain_name = "es-test-2"

  cluster_config {
    instance_count         = 2
    zone_awareness_enabled = true
    instance_type          = "t2.small.elasticsearch"
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
  }
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

data "aws_iam_policy_document" "firehose-elasticsearch" {
  statement {
    effect  = "Allow"
    actions = ["es:*"]

    resources = [
      aws_elasticsearch_domain.test_cluster.arn,
      "${aws_elasticsearch_domain.test_cluster.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "firehose-elasticsearch" {
  name   = "elasticsearch"
  role   = aws_iam_role.firehose_role.id
  policy = data.aws_iam_policy_document.firehose-elasticsearch.json
}

resource "aws_elasticsearch_domain_policy" "main" {
  domain_name = aws_elasticsearch_domain.test_cluster.domain_name

  access_policies = <<POLICIES
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "es:*",
            "Principal": "*",
            "Effect": "Allow",
            "Condition": {
                "IpAddress": {"aws:SourceIp": "127.0.0.1/32"}
            },
            "Resource": "${aws_elasticsearch_domain.test_cluster.arn}/*"
        }
    ]
}
POLICIES
}

resource "aws_kinesis_firehose_delivery_stream" "test" {
  name        = "terraform-kinesis-firehose-es"
  destination = "elasticsearch"

  elasticsearch_configuration {
    domain_arn = aws_elasticsearch_domain.test_cluster.arn
    role_arn   = aws_iam_role.firehose_role.arn
    index_name = "test"
    type_name  = "test"

    s3_configuration {
      role_arn   = aws_iam_role.firehose_role.arn
      bucket_arn = aws_s3_bucket.januarythird.arn
      buffering_size     = 10
      buffering_interval = 400
      compression_format = "GZIP"
    }
  }
}