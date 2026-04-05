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

resource "aws_iam_role" "firehose_role" {
  name = "firehose_redshift_role"

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
  name        = "firehose_redshift_s3_policy"
  description = "Policy for Kinesis Firehose to access S3 and Redshift"

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
          aws_s3_bucket.januarysecond.arn,
          "${aws_s3_bucket.januarysecond.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "redshift:DescribeClusters",
          "redshift:GetClusterCredentials",
          "redshift:CopyFromS3",
          "redshift:CreateClusterUser"
        ],
        Resource = aws_redshift_cluster.test_cluster.arn
      },
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "firehose_policy_attach" {
  role       = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.firehose_policy.arn
}

resource "aws_s3_bucket" "januarysecond" {
  bucket = "januarysecond"
}

resource "aws_redshift_cluster" "test_cluster" {
  cluster_identifier = "tf-redshift-cluster"
  database_name      = "test"
  master_username    = "testuser"
  master_password    = "T3stPass"
  node_type          = "ra3.xlplus"
  cluster_type       = "single-node"
}

resource "aws_kinesis_firehose_delivery_stream" "test_stream" {
  name        = "terraform-kinesis-firehose-test-stream"
  destination = "redshift"

  redshift_configuration {
    role_arn           = aws_iam_role.firehose_role.arn
    cluster_jdbcurl    = "jdbc:redshift://${aws_redshift_cluster.test_cluster.endpoint}/${aws_redshift_cluster.test_cluster.database_name}"
    username           = "testuser"
    password           = "T3stPass"
    data_table_name    = "test-table"
    copy_options       = "delimiter '|'" # the default delimiter
    data_table_columns = "test-col"
    s3_backup_mode     = "Disabled"

    s3_configuration {
      role_arn           = aws_iam_role.firehose_role.arn
      bucket_arn         = aws_s3_bucket.januarysecond.arn
      buffering_size     = 10
      buffering_interval = 400
      compression_format = "GZIP"
    }
  }
}