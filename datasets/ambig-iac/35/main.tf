provider "aws" {
  region = "us-west-2"
}

resource "aws_kinesis_stream" "test_stream" {
  name             = "drow1"
  shard_count      = 1
  retention_period = 48

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }

  tags = {
    Environment = "test"
  }
}