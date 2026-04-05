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

resource "aws_s3_bucket" "video_content" {
  bucket_prefix = "video-content-"
}

resource "aws_s3_object" "put_website" {
  bucket = aws_s3_bucket.video_content.bucket
  key = "index.html"
  source = "./supplement/index.html"
  content_type = "text/html"
}

resource "aws_s3_object" "put_website_css" {
  bucket = aws_s3_bucket.video_content.bucket
  key = "css/style.css"
  source = "./supplement/css/style.css"
  content_type = "text/css"
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.video_content.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action = "s3:GetObject"
        Resource = "${aws_s3_bucket.video_content.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.my_distribution.arn
          }
        }
      }
    ]
  })
}


locals {
  s3_origin_id = "s3_video_content_origin"
}

resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "s3-oac"
  description                       = "aws access control policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "my_distribution" {
  origin {
    domain_name              = aws_s3_bucket.video_content.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# Route53
resource "aws_route53_zone" "my_zone" {
  name = "my-test-cloudfront.com"
}

resource "aws_route53_record" "cdn_ipv4" {
  type    = "A"
  name    = "cdn"
  zone_id = aws_route53_zone.my_zone.zone_id

  alias {
    name                   = aws_cloudfront_distribution.my_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.my_distribution.hosted_zone_id
    evaluate_target_health = true
  }
}