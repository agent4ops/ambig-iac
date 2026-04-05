provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "example53" {
  name = "example53.com"
}

resource "aws_route53_record" "example53_A" {
  zone_id = aws_route53_zone.example53.zone_id
  name    = "example53.com"
  type    = "A"
  ttl     = "300"
  records = ["192.0.2.1"]  
}