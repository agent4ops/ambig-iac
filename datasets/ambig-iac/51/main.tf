provider "aws" {
  region = "us-west-2"
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


resource "aws_iam_role" "kinesis_role" {
  name               = "kinesis_role"
  assume_role_policy = data.aws_iam_policy_document.KinesisAssume.json
}

resource "aws_kinesisanalyticsv2_application" "flink_app" {
  name                 = "example-application1"
  runtime_environment  = "SQL-1_0"
  service_execution_role = aws_iam_role.kinesis_role.arn
}