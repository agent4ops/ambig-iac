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


data "aws_ami" "amzn2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["*ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_instance" "cloud_desktop" {
  instance_type = "t2.micro"
  ami = data.aws_ami.amzn2.id
}

resource "aws_backup_plan" "cloud_desktop_backup" {
  name = "cloud_desktop_backup_plan"
  rule {
    rule_name         = "cloud_desktop_backup_rule" # required, not specified
    target_vault_name = aws_backup_vault.valut.name # required, not specified
    schedule          = "cron(0 0 * * ? *)"
  }

  advanced_backup_setting {
    backup_options = {
      WindowsVSS = "enabled"
    }
    resource_type = "EC2"
  }
}

resource "aws_backup_vault" "valut" {
  name = "cloud_desktop_backup_valut"
}

resource "aws_backup_selection" "backup_ec2" {
  iam_role_arn = aws_iam_role.backup.arn

  name    = "backup_ec2"
  plan_id = aws_backup_plan.cloud_desktop_backup.id

  resources = [
    aws_instance.cloud_desktop.arn,
  ]
}

data "aws_iam_policy_document" "backup_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "backup" {
  name               = "backup"
  assume_role_policy = data.aws_iam_policy_document.backup_assume_role.json
}

resource "aws_iam_role_policy_attachment" "backup" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.backup.name
}