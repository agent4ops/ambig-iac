provider "aws" {
  region     = "us-east-1"
}

resource "aws_lightsail_instance" "test" {
  name              = "custom_instance"
  availability_zone = "us-east-1b"
  blueprint_id      = "amazon_linux_2"
  bundle_id         = "nano_2_0"
  add_on {
    type          = "AutoSnapshot"
    snapshot_time = "06:00"
    status        = "Enabled"
  }
  tags = {
    foo = "bar"
  }
}