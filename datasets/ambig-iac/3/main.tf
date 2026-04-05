terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.75"
      configuration_aliases = [ aws.main, aws.us_east, aws.eu_central, aws.ap_southeast ]
    }
  }

  required_version = ">= 1.9.0"
}


provider "aws" {
  alias = "main"
  region = "us-west-2" 
}

provider "aws" {
  alias  = "us_east"
  region = "us-east-1" # Example region for US East
}

provider "aws" {
  alias  = "eu_central"
  region = "eu-central-1" # Example region for EU Central
}

provider "aws" {
  alias  = "ap_southeast"
  region = "ap-southeast-1" # Example region for AP Southeast
}

resource "aws_db_instance" "primary" {
  provider = aws.main
  identifier = "master"
  allocated_storage    = 20
  engine               = "postgres"
  instance_class       = "db.t3.micro"
  username             = "dbadmin"
  password             = "your_password_here"
  skip_final_snapshot  = true
  backup_retention_period  = 7
}

resource "aws_db_instance" "replica_us_east" {
  provider             = aws.us_east
  replicate_source_db  = aws_db_instance.primary.arn
  instance_class       = "db.t3.micro"
  identifier           = "mydb-replica-us-east"
  skip_final_snapshot  = true
}

resource "aws_db_instance" "replica_eu_central" {
  provider             = aws.eu_central
  replicate_source_db  = aws_db_instance.primary.arn
  instance_class       = "db.t3.micro"
  identifier           = "mydb-replica-eu-central"
  skip_final_snapshot  = true
}

resource "aws_db_instance" "replica_ap_southeast" {
  provider             = aws.ap_southeast
  replicate_source_db  = aws_db_instance.primary.arn
  
  instance_class       = "db.t3.micro"
  identifier           = "mydb-replica-ap-southeast"
  skip_final_snapshot  = true
}

# Route53 Hosted Zone
resource "aws_route53_zone" "main" {
  provider = aws.main
  name = "example53.com"
}


# Route53 Records for each RDS Read Replica with a Weighted Routing Policy
resource "aws_route53_record" "replica_us_east_cname" {
  provider = aws.us_east

  zone_id = aws_route53_zone.main.zone_id
  name    = "us.east.example53.com"
  type    = "CNAME"
  records = [aws_db_instance.replica_us_east.endpoint]
  ttl     = "60"
  weighted_routing_policy {
    weight = 30
  }
  set_identifier = "replica-us-east"
}

resource "aws_route53_record" "replica_eu_central_cname" {
  provider = aws.eu_central

  zone_id = aws_route53_zone.main.zone_id
  name    = "eu.central.example53.com"
  type    = "CNAME"
  records = [aws_db_instance.replica_eu_central.endpoint]
  ttl     = "60"
  weighted_routing_policy {
    weight = 30
  }
  set_identifier = "replica-eu-central"
}

resource "aws_route53_record" "replica_ap_southeast_cname" {
  provider = aws.ap_southeast

  zone_id = aws_route53_zone.main.zone_id
  name    = "ap.southeast.example53.com"
  type    = "CNAME"
  records = [aws_db_instance.replica_ap_southeast.endpoint]
  ttl     = "60"
  weighted_routing_policy {
    weight = 30
  }
  set_identifier = "replica-ap-southeast"
}