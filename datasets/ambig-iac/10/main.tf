provider "aws" {
  region = "us-east-1"
}

# Create Reverse DNS Hosted Zone
resource "aws_route53_zone" "reverse_zone" {
  name = "2.0.192.in-addr.arpa"
}

# Create a PTR Record for a specific IP address within that zone
resource "aws_route53_record" "ptr_record" {
  zone_id = aws_route53_zone.reverse_zone.zone_id
  name    = "53.2.0.192.in-addr.arpa"
  type    = "PTR"
  ttl     = "3600"
  records = ["host.example.com"]
}