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

# even though this program seems to be problematic, it's copied from https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kinesis_firehose_delivery_stream
# so I'll leave it unmodified

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

resource "aws_s3_bucket" "decemberthirtysecond" {
  bucket = "decemberthirtysecond"
}
resource "aws_kinesis_firehose_delivery_stream" "extended_s3_stream" {
  name        = "terraform-kinesis-firehose-extended-s3-test-stream"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.decemberthirtysecond.arn
    buffering_size = 64

    # https://docs.aws.amazon.com/firehose/latest/dev/dynamic-partitioning.html
    dynamic_partitioning_configuration {
      enabled = "true"
    }

    # Example prefix using partitionKeyFromQuery, applicable to JQ processor
    prefix              = "data/customer_id=!{partitionKeyFromQuery:customer_id}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
    error_output_prefix = "errors/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/!{firehose:error-output-type}/"

    processing_configuration {
      enabled = "true"

      # Multi-record deaggregation processor example
      processors {
        type = "RecordDeAggregation"
        parameters {
          parameter_name  = "SubRecordType"
          parameter_value = "JSON"
        }
      }

      # New line delimiter processor example
      processors {
        type = "AppendDelimiterToRecord"
      }

      # JQ processor example
      processors {
        type = "MetadataExtraction"
        parameters {
          parameter_name  = "JsonParsingEngine"
          parameter_value = "JQ-1.6"
        }
        parameters {
          parameter_name  = "MetadataExtractionQuery"
          parameter_value = "{customer_id:.customer_id}"
        }
      }
    }
  }
}