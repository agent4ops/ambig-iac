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

resource "aws_redshift_cluster" "example" {
  cluster_identifier = "tf-redshift-cluster"
  database_name      = "mydb"
  master_username    = "exampleuser"
  master_password    = "Mustbe8characters"
  node_type          = "dc2.large"
  cluster_type       = "single-node"
}