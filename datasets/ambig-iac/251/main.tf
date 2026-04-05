provider "aws" {
  region     = "us-east-1"
}

resource "aws_glacier_vault" "example" {
  name = "example"
}

data "aws_iam_policy_document" "example" {
  statement {
    actions   = ["glacier:DeleteArchive"]
    effect    = "Deny"
    resources = [aws_glacier_vault.example.arn]

    condition {
      test     = "NumericLessThanEquals"
      variable = "glacier:ArchiveAgeinDays"
      values   = ["365"]
    }
  }
}

resource "aws_glacier_vault_lock" "example" {
  complete_lock = false
  policy        = data.aws_iam_policy_document.example.json
  vault_name    = aws_glacier_vault.example.name
}