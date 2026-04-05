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

data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

resource "aws_lightsail_disk" "test1" {
  name              = "test-disk-1"
  size_in_gb        = 8
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_lightsail_disk" "test2" {
  name              = "test-disk-2"
  size_in_gb        = 8
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_lightsail_instance" "test" {
  name              = "test-instance"
  availability_zone = data.aws_availability_zones.available.names[0]
  blueprint_id      = "amazon_linux_2"
  bundle_id         = "nano_1_0"
}

resource "aws_lightsail_disk_attachment" "test1" {
  disk_name     = aws_lightsail_disk.test1.name
  instance_name = aws_lightsail_instance.test.name
  disk_path     = "/dev/xvdf"
}

resource "aws_lightsail_disk_attachment" "test2" {
  disk_name     = aws_lightsail_disk.test2.name
  instance_name = aws_lightsail_instance.test.name
  disk_path     = "/dev/xvdg"
}