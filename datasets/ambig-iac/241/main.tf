provider "aws" {
  region     = "us-east-1"
}

resource "aws_lightsail_bucket" "test" {
  name      = "mytestbucket"
  bundle_id = "small_1_0"
}

resource "aws_lightsail_instance" "test" {
  name              = "mytestinstance"
  availability_zone = "us-east-1b"
  blueprint_id      = "amazon_linux_2"
  bundle_id         = "nano_1_0"
}

resource "aws_lightsail_bucket_resource_access" "test" {
  bucket_name   = aws_lightsail_bucket.test.name
  resource_name = aws_lightsail_instance.test.name
}