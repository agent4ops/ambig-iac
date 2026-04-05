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

resource "aws_elasticache_user" "test" {
  user_id       = "testUserId"
  user_name     = "default"
  access_string = "on ~app::* -@all +@read +@hash +@bitmap +@geo -setbit -bitfield -hset -hsetnx -hmset -hincrby -hincrbyfloat -hdel -bitop -geoadd -georadius -georadiusbymember"
  engine        = "REDIS"
  passwords     = ["password123456789"]
}

resource "aws_elasticache_user_group" "test" {
  engine        = "REDIS"
  user_group_id = "userGroupId"
  user_ids      = [aws_elasticache_user.test.user_id]
}