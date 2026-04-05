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

resource "aws_elasticache_user" "default" { 
  user_id = "defaultUserID" 
  user_name = "default" 
  access_string = "on ~app::* -@all +@read +@hash +@bitmap +@geo -setbit -bitfield -hset -hsetnx -hmset -hincrby -hincrbyfloat -hdel -bitop -geoadd -georadius -georadiusbymember" 
  engine = "REDIS" 
  passwords = ["password123456789"] 
} 

resource "aws_elasticache_user_group" "example"{ 
  engine = "REDIS" 
  user_group_id = "userGroupId" 
  user_ids = [aws_elasticache_user.default.user_id] 
  lifecycle { ignore_changes = [user_ids] } 
} 

resource "aws_elasticache_user" "example" { 
  user_id = "exampleUserID" 
  user_name = "exampleuser" 
  access_string = "on ~app::* -@all +@read +@hash +@bitmap +@geo -setbit -bitfield -hset -hsetnx -hmset -hincrby -hincrbyfloat -hdel -bitop -geoadd -georadius -georadiusbymember" 
  engine = "REDIS" 
  passwords = ["password123456789"] 
} 

resource "aws_elasticache_user_group_association" "example" { 
  user_group_id = aws_elasticache_user_group.example.user_group_id 
  user_id = aws_elasticache_user.example.user_id 
}