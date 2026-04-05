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

resource "aws_chime_voice_connector" "default" {
  name               = "vc-name-test"
  require_encryption = true
}

resource "aws_chime_voice_connector_streaming" "default" {
  disabled = false
  voice_connector_id  = aws_chime_voice_connector.default.id
  data_retention = 5
  streaming_notification_targets = ["SNS"]
}