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

data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

resource "aws_lightsail_static_ip_attachment" "test" {
  static_ip_name = aws_lightsail_static_ip.test.name
  instance_name  = aws_lightsail_instance.test.name
}

resource "aws_lightsail_static_ip" "test" {
  name = "test-static-ip"
}

resource "aws_lightsail_instance" "test" {
  name              = "test-instance"
  availability_zone = data.aws_availability_zones.available.names[0]
  blueprint_id      = "amazon_linux_2"
  bundle_id         = "micro_1_0"
}

resource "aws_lightsail_distribution" "test" {
  name       = "test-distribution"
  depends_on = [aws_lightsail_static_ip_attachment.test]
  bundle_id  = "small_1_0"
  origin {
    name        = aws_lightsail_instance.test.name
    region_name = data.aws_availability_zones.available.id
  }
  default_cache_behavior {
    behavior = "cache"
  }
}