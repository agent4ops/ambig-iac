provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "example" {
  name = "example53.com"
}

# TXT Record for domain verification or other purposes
resource "aws_route53_record" "example_txt" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "sub.example53.com"
  type    = "TXT"
  ttl     = "300"
  records = ["passwordpassword"] 
}