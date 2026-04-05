provider "aws" {
  region     = "us-east-1"
}

resource "aws_lightsail_static_ip_attachment" "test" {
  static_ip_name = aws_lightsail_static_ip.test.id
  instance_name  = aws_lightsail_instance.test.id
}

resource "aws_lightsail_static_ip" "test" {
  name = "example"
}

resource "aws_lightsail_instance" "test" {
  name              = "custom_gitlab"
  availability_zone = "us-east-1b"
  blueprint_id      = "amazon_linux_2"
  bundle_id         = "nano_2_0"
}