terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "example_vpc1" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_vpc" "example_vpc2" {
  cidr_block = "10.1.0.0/16"
}

resource "aws_vpc_peering_connection" "example_peer" {
  vpc_id        = aws_vpc.example_vpc1.id
  peer_vpc_id   = aws_vpc.example_vpc2.id
  auto_accept   = true
}