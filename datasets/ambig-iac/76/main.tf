terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.75"
    }
  }

  required_version = ">= 1.9.0"
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "backstage" {
  bucket_prefix = "test-bucket-"
}

resource "aws_s3_bucket_ownership_controls" "example" {
    bucket = aws_s3_bucket.backstage.id
    rule {
        object_ownership = "BucketOwnerPreferred"
    }
}

resource "aws_s3_bucket_acl" "backstage_acl" {
  depends_on = [ aws_s3_bucket_ownership_controls.example ]
  bucket = aws_s3_bucket.backstage.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backstage_server_side_encription" {
  bucket = aws_s3_bucket.backstage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "backstage" {
  bucket = aws_s3_bucket.backstage.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}