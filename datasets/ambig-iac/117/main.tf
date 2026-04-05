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

resource "aws_elasticache_user" "test" {
  user_id       = "testUserId"
  user_name     = "testUserName"
  access_string = "on ~* +@all"
  engine        = "REDIS"

  authentication_mode {
    type      = "password"
    passwords = ["password1", "password2"]
  }
}