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
  region = "us-east-1"
}

resource "aws_s3_bucket" "artifact_bucket" {
  bucket_prefix = "artifact-bucket-"
}

resource "aws_codebuild_project" "autograder_build" {
  name         = "autograder_build"
  service_role = aws_iam_role.autograder_build_role.arn

  artifacts {
    type     = "S3"
    location = aws_s3_bucket.artifact_bucket.arn
    name     = "results.zip" # include this
  }

  environment { # arguments required, exact value not specified
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:7.0-24.10.29"
    type         = "LINUX_CONTAINER"
  }

  source {
    type            = "GITHUB"
    git_clone_depth = 1 # good to have, not required
    location        = "github.com/source-location"
  }
}

resource "aws_iam_role" "autograder_build_role" {
  assume_role_policy = data.aws_iam_policy_document.autograder_build_policy_assume.json
}

data "aws_iam_policy_document" "autograder_build_policy_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }

}

data "aws_iam_policy_document" "autograder_build_policy" {
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

resource "aws_iam_policy" "autograder_build_policy" {
  name        = "lambda_policy"
  description = "Grants permissions to Lambda to describe vpc, subnet, security group"

  policy = data.aws_iam_policy_document.autograder_build_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.autograder_build_role.name
  policy_arn = aws_iam_policy.autograder_build_policy.arn
}