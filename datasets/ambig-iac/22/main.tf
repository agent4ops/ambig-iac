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

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "test_role7" {
  name               = "test_role7"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}


resource "aws_codebuild_project" "example7" {
  name          = "test-project7"
  service_role  = aws_iam_role.test_role7.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:7.0-24.10.29"
    type         = "LINUX_CONTAINER"
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/neilbalch/SimplePythonTutorial.git"
    git_clone_depth = 1
  }

  secondary_sources {
    source_identifier = "SecondarySource"
    type            = "GITHUB"
    location        = "https://github.com/pH-7/Simple-Java-Calculator.git"
    git_clone_depth =  1
  }
}