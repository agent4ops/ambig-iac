provider "aws" {
  alias  = "alt"
  region = "us-east-2"
}

resource "aws_dynamodb_table" "example" {
  provider         = aws.alt
  name             = "TestTable"
  hash_key         = "BrodoBaggins"
  billing_mode     = "PAY_PER_REQUEST"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "BrodoBaggins"
    type = "S"
  }

  lifecycle {
    ignore_changes = [replica]
  }
}

resource "aws_dynamodb_table_replica" "example" {
  provider         = aws.alt
  global_table_arn = aws_dynamodb_table.example.arn

  tags = {
    Name = "IZPAWS"
    Pozo = "Amargo"
  }
}