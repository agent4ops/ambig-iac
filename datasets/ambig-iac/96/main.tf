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

resource "aws_vpc" "example_vpc" {
  cidr_block          = "10.0.0.0/16"
  enable_dns_support  = true
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.example_vpc.id
}

data "aws_availability_zones" "azs" {
    state = "available"
}

# Create subnet in us-east-1a
resource "aws_subnet" "subnet_a" {
  vpc_id                = aws_vpc.example_vpc.id
  cidr_block            = "10.0.1.0/24"
  availability_zone     = data.aws_availability_zones.azs.names[0]
  map_public_ip_on_launch = true
}

# Create subnet in us-east-1b
resource "aws_subnet" "subnet_b" {
  vpc_id                = aws_vpc.example_vpc.id
  cidr_block            = "10.0.2.0/24"
  availability_zone     = data.aws_availability_zones.azs.names[1]
  map_public_ip_on_launch = true
}

# Create the Redshift subnet group
resource "aws_redshift_subnet_group" "example_subnet_group" {
  name        = "example-subnet-group"
  description = "Example Redshift subnet group"

  subnet_ids = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
}

resource "aws_redshift_cluster" "example" {
  cluster_identifier = "redshift-cluster-1"
  node_type          = "dc2.large"
  cluster_type       = "multi-node"
  number_of_nodes    = 2

  database_name = "mydb"
  master_username = "foo"
  master_password = "Mustbe8characters"

  cluster_subnet_group_name   = aws_redshift_subnet_group.example_subnet_group.name

  skip_final_snapshot = true
}