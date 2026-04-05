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

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "firehose_role" {
  name = "firehose_opensearch_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "firehose.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "firehose_policy" {
  name        = "firehose_opensearch_s3_policy"
  description = "Policy for Kinesis Firehose to access S3 and OpenSearch Serverless"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:GetObject"
        ],
        Resource = [
          aws_s3_bucket.januarysixth.arn,
          "${aws_s3_bucket.januarysixth.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "es:ESHttpPut",
          "es:ESHttpPost",
          "es:ESHttpGet"
        ],
        Resource = [
          "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:collection/${aws_opensearchserverless_collection.test_collection.name}/*",
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "firehose_policy_attach" {
  role       = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.firehose_policy.arn
}

resource "aws_s3_bucket" "januarysixth" {
  bucket = "januarysixth"
}
resource "aws_opensearchserverless_security_policy" "example" {
  name = "example"
  type = "encryption"
  policy = jsonencode({
    "Rules" = [
      {
        "Resource" = [
          "collection/example"
        ],
        "ResourceType" = "collection"
      }
    ],
    "AWSOwnedKey" = true
  })
}

resource "aws_opensearchserverless_collection" "test_collection" {
  name = "example"
  depends_on = [aws_opensearchserverless_security_policy.example]
}

resource "aws_kinesis_firehose_delivery_stream" "test_stream" {
  name        = "terraform-kinesis-firehose-test-stream"
  destination = "opensearchserverless"

  opensearchserverless_configuration {
    collection_endpoint = aws_opensearchserverless_collection.test_collection.collection_endpoint
    role_arn            = aws_iam_role.firehose_role.arn
    index_name          = "test"

    s3_configuration {
      role_arn           = aws_iam_role.firehose_role.arn
      bucket_arn         = aws_s3_bucket.januarysixth.arn
      buffering_size     = 10
      buffering_interval = 400
      compression_format = "GZIP"
    }
  }
}