provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "primary" {
  name = "example53.com"
}

resource "aws_elb" "main" {
  name               = "sample"
  availability_zones = ["us-east-1c"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "example53.com"
  type    = "A"

  alias {
    name                   = aws_elb.main.dns_name
    zone_id                = aws_elb.main.zone_id
    evaluate_target_health = true
  }
}