terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_sns_topic" "topic" {
  name   = "s3-event-notification-topic"
}

resource "aws_s3_bucket" "bucket" {
  bucket = "your-bucket-name"
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.bucket.id

  topic {
    topic_arn     = aws_sns_topic.topic.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".log"
  }
}