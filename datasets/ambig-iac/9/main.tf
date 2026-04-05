provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "example53" {
  name = "example53.com"
}

resource "aws_route53_record" "example53_A" {
  zone_id = aws_route53_zone.example53.zone_id
  name    = "example53.com"
  type    = "AAAA"
  ttl     = "300"
  records = ["2001:0db8:85a3:0000:0000:8a2e:0370:7334"]  
}