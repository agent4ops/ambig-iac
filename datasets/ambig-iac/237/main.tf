provider "aws" {
  region     = "us-east-1"
}

data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

resource "aws_lightsail_disk" "test" {
  name              = "test"
  size_in_gb        = 8
  availability_zone = data.aws_availability_zones.available.names[0]
}