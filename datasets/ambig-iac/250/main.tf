provider "aws" {
  region     = "us-east-1"
}

data "aws_iam_policy_document" "my_archive" {
  statement {
    sid    = "add-read-only-perm"
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "glacier:InitiateJob",
      "glacier:GetJobOutput",
    ]

    resources = ["arn:aws:glacier:eu-west-1:432981146916:vaults/MyArchive"]
  }
}

resource "aws_glacier_vault" "my_archive" {
  name = "MyArchive"
  access_policy = data.aws_iam_policy_document.my_archive.json

  tags = {
    Test = "MyArchive"
  }
}