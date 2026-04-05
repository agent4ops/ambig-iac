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

resource "aws_iam_role" "test_role11" {
  name = "test_role11"

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

resource "aws_s3_bucket" "aprilthirthyfirst" {
  bucket = "aprilthirthyfirst"
}

resource "aws_s3_bucket" "aprilthirthyfirst2" {
  bucket = "aprilthirthyfirst2"
}

resource "aws_codebuild_project" "example11" {
  name          = "test-project11"
  service_role  = aws_iam_role.test_role11.arn

  artifacts {
    location  = aws_s3_bucket.aprilthirthyfirst.bucket
    name     = "results.zip"
    type      = "S3"
    path      = "/"
    packaging = "ZIP"
  }

  secondary_artifacts {
    artifact_identifier =  "SecondaryArtifact"
    location  = aws_s3_bucket.aprilthirthyfirst2.bucket
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

    environment_variable {
      name  = "SOME_KEY1"
      value = "SOME_VALUE1"
    }

    environment_variable {
      name  = "SOME_KEY2"
      value = "SOME_VALUE2"
      type  = "PARAMETER_STORE"
    }

  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/mitchellh/packer.git"
    git_clone_depth = 1
  }

  source_version = "master"

  secondary_sources {
    source_identifier = "source2"
    type            = "GITHUB"
    location        = "https://github.com/mitchellh/packer.git"
    git_clone_depth = 1
  }

  secondary_source_version {
    source_identifier = "source2"
    source_version = "master"
  }
}