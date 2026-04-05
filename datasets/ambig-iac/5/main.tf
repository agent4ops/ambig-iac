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


resource "aws_db_instance" "primary" {
  identifier = "primary"
  allocated_storage    = 20
  engine               = "postgres"
  instance_class       = "db.t3.micro"
  username             = "dbadmin"
  password             = "your_password_here"
  skip_final_snapshot  = true
  backup_retention_period  = 7
}

resource "aws_db_instance" "replica_1" {
  replicate_source_db  = aws_db_instance.primary.identifier
  instance_class       = "db.t3.micro"
  identifier           = "mydb-replica-1"
  skip_final_snapshot  = true
}

resource "aws_db_instance" "replica_2" {
  replicate_source_db  = aws_db_instance.primary.identifier
  instance_class       = "db.t3.micro"
  identifier           = "mydb-replica-2"
  skip_final_snapshot  = true
}


# Route53 Hosted Zone
resource "aws_route53_zone" "main" {
  name = "example53.com"
}


# Route53 Records for each RDS Read Replica with a Weighted Routing Policy
resource "aws_route53_record" "replica_1_cname" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "replica1.example53.com"
  type    = "CNAME"
  records = [aws_db_instance.replica_1.endpoint]
  ttl     = "60"
  weighted_routing_policy {
    weight = 10
  }
  set_identifier = "replica-1-record"
}

resource "aws_route53_record" "replica_2_cname" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "replica2.example53.com"
  type    = "CNAME"
  records = [aws_db_instance.replica_2.endpoint]
  ttl     = "60"
  weighted_routing_policy {
    weight = 20
  }
  set_identifier = "replica-2-record"
}