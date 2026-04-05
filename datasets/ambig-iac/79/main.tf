provider "aws" {
    region = "us-west-1"
}

resource "aws_s3_bucket" "a" {
  bucket = "pike-680235478471"
}

resource "aws_s3_bucket_request_payment_configuration" "pike" {
  bucket = "pike-680235478471"
  payer  = "Requester"
}