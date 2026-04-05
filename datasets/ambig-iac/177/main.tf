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

resource "aws_iam_group" "group" {
  name = "test-group"
}

data "aws_iam_policy_document" "example" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "policy" {
  name        = "test-policy"
  description = "A test policy"
  policy      = data.aws_iam_policy_document.example.json
}

resource "aws_iam_group_policy_attachment" "test-attach" {
  group      = aws_iam_group.group.name
  policy_arn = aws_iam_policy.policy.arn
}