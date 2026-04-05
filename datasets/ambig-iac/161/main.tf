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

resource "aws_chime_voice_connector" "vc1" {
  name               = "connector-test-1"
  require_encryption = true
  aws_region         = "us-east-1"
}

resource "aws_chime_voice_connector" "vc2" {
  name               = "connector-test-2"
  require_encryption = true
  aws_region         = "us-west-2"
}

resource "aws_chime_voice_connector_group" "group" {
  name = "test-group"

  connector {
    voice_connector_id = aws_chime_voice_connector.vc1.id
    priority           = 1
  }

  connector {
    voice_connector_id = aws_chime_voice_connector.vc2.id
    priority           = 3
  }
}