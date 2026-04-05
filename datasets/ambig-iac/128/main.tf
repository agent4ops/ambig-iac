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

resource "aws_vpc" "vpc" {
    cidr_block = "192.168.0.0/22"
    enable_dns_support = true
    enable_dns_hostnames = true
}

data "aws_availability_zones" "azs" {
    state = "available"
}

resource "aws_subnet" "subnet_az1" {
    availability_zone = data.aws_availability_zones.azs.names[0]
    cidr_block = "192.168.0.0/24"
    vpc_id = aws_vpc.vpc.id
    map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet_az2" {
    availability_zone = data.aws_availability_zones.azs.names[1]
    cidr_block = "192.168.1.0/24"
    vpc_id = aws_vpc.vpc.id
    map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet_az3" {
    availability_zone = data.aws_availability_zones.azs.names[2]
    cidr_block = "192.168.2.0/24"
    vpc_id = aws_vpc.vpc.id
    map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "first" {
  subnet_id      = aws_subnet.subnet_az1.id
  route_table_id = aws_route_table.main.id
}

resource "aws_route_table_association" "second" {
  subnet_id      = aws_subnet.subnet_az2.id
  route_table_id = aws_route_table.main.id
}

resource "aws_route_table_association" "third" {
  subnet_id      = aws_subnet.subnet_az3.id
  route_table_id = aws_route_table.main.id
}

resource "aws_security_group" "sg" {
    vpc_id = aws_vpc.vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "ingress1" {
  security_group_id = aws_security_group.sg.id
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "-1"
}

resource "aws_vpc_security_group_egress_rule" "egress1" {
  security_group_id = aws_security_group.sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_msk_serverless_cluster" "example" {
    cluster_name = "Example"

    vpc_config {
        subnet_ids = [aws_subnet.subnet_az1.id, aws_subnet.subnet_az2.id, aws_subnet.subnet_az3.id]
        security_group_ids = [aws_security_group.sg.id]
    }

    client_authentication {
        sasl {
            iam {
                enabled = true
            }
        }
    }
}