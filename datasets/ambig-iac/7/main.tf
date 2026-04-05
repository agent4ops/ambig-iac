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
  region  = "us-east-1"
}

resource "aws_iam_role" "eb_ec2_role" {
  name = "elastic_beanstalk_ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
      },
    ]
  })
}

# Attach the AWS managed policy for Elastic Beanstalk to the role
resource "aws_iam_role_policy_attachment" "eb_managed_policy" {
  role       = aws_iam_role.eb_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}


# Create an instance profile tied to the role
resource "aws_iam_instance_profile" "eb_ec2_profile" {
  name = "elastic_beanstalk_ec2_profile"
  role = aws_iam_role.eb_ec2_role.name
}

resource "aws_s3_bucket" "sample_bucket" {
  bucket_prefix = "sample-"
}

resource "aws_s3_object" "examplebucket_blue_object" {
  key    = "blue_app"
  bucket = aws_s3_bucket.sample_bucket.id
  source = "./supplement/app.zip"
}

resource "aws_s3_object" "examplebucket_green_object" {
  key    = "green_app"
  bucket = aws_s3_bucket.sample_bucket.id
  source = "./supplement/app.zip"
}

# Elastic Beanstalk application
resource "aws_elastic_beanstalk_application" "blue_app" {
  name        = "blue-app"
  description = "An application for Blue deployment."
}

resource "aws_elastic_beanstalk_application_version" "blue_version" {
  name        = "v1"
  application = aws_elastic_beanstalk_application.blue_app.name
  bucket = aws_s3_object.examplebucket_blue_object.bucket
  key    = aws_s3_object.examplebucket_blue_object.key
}

resource "aws_elastic_beanstalk_application" "green_app" {
  name        = "green-app"
  description = "An application for Green deployment."
}

resource "aws_elastic_beanstalk_application_version" "green_version" {
  name        = "v2"
  application = aws_elastic_beanstalk_application.green_app.name
  bucket = aws_s3_object.examplebucket_green_object.bucket
  key    = aws_s3_object.examplebucket_green_object.key
}

# Blue environment
resource "aws_elastic_beanstalk_environment" "blue" {
  name                = "${aws_elastic_beanstalk_application.blue_app.name}"
  application         = aws_elastic_beanstalk_application.blue_app.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.3.0 running Python 3.9"
  version_label = aws_elastic_beanstalk_application_version.blue_version.name

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2_profile.name
  }
}

# Green environment (New version)
resource "aws_elastic_beanstalk_environment" "green" {
  name                = "${aws_elastic_beanstalk_application.green_app.name}-green"
  application         = aws_elastic_beanstalk_application.green_app.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.3.0 running Python 3.9"
  version_label = aws_elastic_beanstalk_application_version.green_version.name

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2_profile.name
  }
}

# Route53 Hosted Zone
resource "aws_route53_zone" "main" {
  name = "example53.com"
}

# Weighted DNS records for Blue and Green environments
resource "aws_route53_record" "blue" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.example.com"
  type    = "CNAME"
  ttl     = "60"
  weighted_routing_policy {
    weight = 120
  }
  set_identifier = "BlueEnvironment"
  records = [
    aws_elastic_beanstalk_environment.blue.cname
  ]
}

resource "aws_route53_record" "green" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.example.com"
  type    = "CNAME"
  ttl     = "60"
  weighted_routing_policy {
    weight = 60
  }
  set_identifier = "GreenEnvironment"
  records = [
    aws_elastic_beanstalk_environment.green.cname
  ]
}