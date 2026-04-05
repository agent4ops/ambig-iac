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

resource "aws_iam_role" "firehose_role2" {
  name = "firehose_http_s3_role"

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

resource "aws_iam_policy" "firehose_http_s3_policy" {
  name        = "firehose_http_s3_policy"
  description = "Policy for Kinesis Firehose to access S3 and HTTP endpoint"

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
          aws_s3_bucket.januaryeleventh.arn,
          "${aws_s3_bucket.januaryeleventh.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "firehose:DescribeDeliveryStream",
          "firehose:ListDeliveryStreams",
          "firehose:DescribeDestinations",
          "firehose:DescribeHttpEndpointDestination",
          "firehose:UpdateDestination"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "firehose_http_s3_policy_attach" {
  role       = aws_iam_role.firehose_role2.name
  policy_arn = aws_iam_policy.firehose_http_s3_policy.arn
}

resource "aws_s3_bucket" "januaryeleventh" {
  bucket = "januaryeleventh"
}
resource "aws_kinesis_firehose_delivery_stream" "test_stream" {
  name        = "terraform-kinesis-firehose-test-stream"
  destination = "http_endpoint"

  http_endpoint_configuration {
    url                = "https://aws-api.newrelic.com/firehose/v1"
    name               = "New Relic"
    access_key         = "my-key"
    buffering_size     = 15
    buffering_interval = 600
    role_arn           = aws_iam_role.firehose_role2.arn
    s3_backup_mode     = "FailedDataOnly"

    s3_configuration {
      role_arn           = aws_iam_role.firehose_role2.arn
      bucket_arn         = aws_s3_bucket.januaryeleventh.arn
      buffering_size     = 10
      buffering_interval = 400
      compression_format = "GZIP"
    }

    request_configuration {
      content_encoding = "GZIP"

      common_attributes {
        name  = "testname"
        value = "testvalue"
      }

      common_attributes {
        name  = "testname2"
        value = "testvalue2"
      }
    }
  }
}