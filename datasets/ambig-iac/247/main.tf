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

resource "aws_glacier_vault" "example" {
  name = "my-glacier-vault"
}

resource "aws_dlm_lifecycle_policy" "example" {
  description = "Automated archiving policy"

  execution_role_arn = "arn:aws:iam::123456789012:role/DLMServiceRole"  # Replace with your DLM execution role ARN

  policy_details {
    resource_types = ["VOLUME"]
    target_tags = {
      "archive" = "true"
    }
    schedule {
      name = "2 weeks of daily snapshots"

      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = ["23:45"]
      }

      retain_rule {
        count = 14
      }

      tags_to_add = {
        SnapshotCreator = "DLM"
      }

      copy_tags = false
    }
  }
}