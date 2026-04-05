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

resource "aws_sns_topic" "aws_sns_topic" {
  name = "glacier-sns-topic"
}

data "aws_iam_policy_document" "my_archive" {
  statement {
    sid    = "add-read-only-perm"
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "glacier:InitiateJob",
      "glacier:GetJobOutput",
    ]

    resources = ["arn:aws:glacier:eu-west-1:432981146916:vaults/MyArchive"]
  }
}

resource "aws_glacier_vault" "my_archive" {
  name = "MyArchive"

  notification {
    sns_topic = aws_sns_topic.aws_sns_topic.arn
    events    = ["ArchiveRetrievalCompleted", "InventoryRetrievalCompleted"]
  }

  access_policy = data.aws_iam_policy_document.my_archive.json

  tags = {
    Test = "MyArchive"
  }
}