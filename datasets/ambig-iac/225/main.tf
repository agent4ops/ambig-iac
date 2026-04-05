provider "aws" {
  region     = "us-east-1"
}

resource "aws_lightsail_instance" "custom" {
  name              = "custom"
  availability_zone = "us-east-1a"
  blueprint_id      = "amazon_linux_2"
  bundle_id         = "nano_2_0"
}