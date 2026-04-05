provider "aws" {
  region     = "us-east-1"
}

resource "aws_lightsail_instance" "gitlab_test" {
  name              = "custom_gitlab"
  availability_zone = "us-east-1b"
  blueprint_id      = "amazon_linux_2"
  bundle_id         = "nano_2_0"
}