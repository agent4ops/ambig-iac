provider "aws" {
  region     = "us-east-1"
}

resource "aws_lightsail_instance" "custom" {
  name              = "custom"
  availability_zone = "us-east-1b"
  blueprint_id      = "wordpress"
  bundle_id         = "nano_2_0"
 }