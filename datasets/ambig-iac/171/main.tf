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

resource "aws_redshift_cluster" "example" {
  cluster_identifier = "tf-redshift-cluster"
  database_name      = "mydb"
  master_username    = "exampleuser"
  master_password    = "Mustbe8characters"
  node_type          = "ra3.xlplus"
  cluster_type       = "single-node"
}

resource "aws_redshift_endpoint_access" "example" {
  endpoint_name      = "example"
  subnet_group_name  = aws_redshift_subnet_group.foobar.id
  cluster_identifier = aws_redshift_cluster.example.cluster_identifier
}

resource "aws_vpc" "foo" {
  cidr_block = "10.1.0.0/16"
}

data "aws_availability_zones" "azs" {
    state = "available"
}

resource "aws_subnet" "foo" {
  cidr_block        = "10.1.1.0/24"
  availability_zone = data.aws_availability_zones.azs.names[0]
  vpc_id            = aws_vpc.foo.id
}

resource "aws_subnet" "bar" {
  cidr_block        = "10.1.2.0/24"
  availability_zone = data.aws_availability_zones.azs.names[1]
  vpc_id            = aws_vpc.foo.id
}

resource "aws_redshift_subnet_group" "foobar" {
  name       = "foo"
  subnet_ids = [aws_subnet.foo.id, aws_subnet.bar.id]
}