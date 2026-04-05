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

resource "aws_lightsail_bucket" "test" {
  name      = "test-bucket"
  bundle_id = "small_1_0"
}
resource "aws_lightsail_distribution" "test" {
  name      = "test-distribution"
  bundle_id = "small_1_0"
  origin {
    name        = aws_lightsail_bucket.test.name
    region_name = aws_lightsail_bucket.test.region
  }
  default_cache_behavior {
    behavior = "cache"
  }
  cache_behavior_settings {
    allowed_http_methods = "GET,HEAD,OPTIONS,PUT,PATCH,POST,DELETE"
    cached_http_methods  = "GET,HEAD"
    default_ttl          = 86400
    maximum_ttl          = 31536000
    minimum_ttl          = 0
    forwarded_cookies {
      option = "none"
    }
    forwarded_headers {
      option = "default"
    }
    forwarded_query_strings {
      option = false
    }
  }
}