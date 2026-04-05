# Define the provider block for AWS
provider "aws" {
  region = "us-east-2" # Set your desired AWS region
}

resource "aws_db_instance" "default" {
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = "db.z1d.micro"
  username             = "foo"
  password             = "foobarbaz"
  apply_immediately = true
}