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


data "aws_iam_policy_document" "StreamReaderWriter" {
  statement {
    effect = "Allow"
    actions = ["kinesis:DescribeStream",
               "kinesis:GetShardIterator",
               "kinesis:GetRecords"]
    resources = [aws_kinesis_stream.test_stream.arn]
  }
}

data "aws_iam_policy_document" "KinesisAssume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["kinesisanalytics.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "StreamReaderWriter" {
  name   = "KinesisStreamReaderWriter"
  policy = data.aws_iam_policy_document.StreamReaderWriter.json
}

resource "aws_iam_role" "kinesis_role" {
  name               = "kinesis_role"
  assume_role_policy = data.aws_iam_policy_document.KinesisAssume.json
}

resource "aws_iam_role_policy_attachment" "attach_kinesis_role" {
  role       = aws_iam_role.kinesis_role.name
  policy_arn = aws_iam_policy.StreamReaderWriter.arn
}

resource "aws_kinesis_stream" "test_stream" {
  name             = "events"
  shard_count      = 1
  retention_period = 168
}


resource "aws_kinesis_analytics_application" "test_application" {
  name = "kinesis-analytics-application-test"

  inputs {
    name_prefix = "test_prefix"

    kinesis_stream {
      resource_arn = aws_kinesis_stream.test_stream.arn
      role_arn     = aws_iam_role.kinesis_role.arn
    }

    parallelism {
      count = 1
    }

    schema {
      record_columns {
        mapping  = "$.test"
        name     = "test"
        sql_type = "VARCHAR(8)"
      }

      record_encoding = "UTF-8"

      record_format {
        mapping_parameters {
          json {
            record_row_path = "$"
          }
        }
      }
    }
  }
}