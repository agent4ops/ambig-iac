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

resource "aws_iam_role" "test_role9" {
  name = "test_role9"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_s3_bucket" "aprilthirthieth" {
  bucket = "aprilthirthieth"
}

resource "aws_codebuild_project" "example9" {
  name          = "test-project9"
  service_role  = aws_iam_role.test_role9.arn

  artifacts {
    location  = aws_s3_bucket.aprilthirthieth.bucket
    name     = "results.zip"
    type      = "S3"
    path      = "/"
    packaging = "ZIP"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0-24.10.29"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/mitchellh/packer.git"
    git_clone_depth = 1
  }

  source_version = "master"

  build_batch_config {
    service_role = aws_iam_role.test_role9.arn
    restrictions {
      maximum_builds_allowed = 4
    }
  }

}