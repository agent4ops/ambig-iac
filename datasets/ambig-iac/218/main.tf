provider "aws" {
  region="us-east-1"
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "random_password" "db" {
  length  = 16
  special = false
}

resource "aws_db_instance" "test" {
  identifier          = "metricbeat-test-${random_id.suffix.hex}"
  allocated_storage   = 20 // Gigabytes
  engine              = "mysql"
  instance_class      = "db.t2.micro"
  db_name                = "metricbeattest"
  username            = "foo"
  password            = random_password.db.result
  skip_final_snapshot = true // Required for cleanup
}