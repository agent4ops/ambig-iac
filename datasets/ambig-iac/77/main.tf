provider "aws" {
    region = "us-west-1"
}

resource "aws_s3_bucket" "sample" {
  bucket = "sample"
}

resource "aws_s3_bucket_versioning" "sample" {
  bucket = "sample"
  versioning_configuration {
    status = "Enabled"
  }
  expected_bucket_owner = "123456789012"
}