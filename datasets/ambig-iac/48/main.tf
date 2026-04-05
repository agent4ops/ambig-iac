provider "aws" {
  region = "us-west-2"
}

resource "aws_kinesis_stream" "example" {
  name        = "example-stream"
  shard_count = 1
}

resource "aws_kinesis_stream_consumer" "example" {
  name       = "example-consumer"
  stream_arn = aws_kinesis_stream.example.arn
}