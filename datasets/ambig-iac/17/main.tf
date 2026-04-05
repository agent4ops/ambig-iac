provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "beanstalk_service" {
  name = "tf-test-beanstalk-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "elasticbeanstalk.amazonaws.com"
        },
      },
    ]
  })
}

resource "aws_elastic_beanstalk_application" "tftest" {
  name        = "tf-test-name"
  description = "tf-test-desc"

  appversion_lifecycle {
    service_role          = aws_iam_role.beanstalk_service.arn
    max_age_in_days = 5
    delete_source_from_s3 = true
  }
}