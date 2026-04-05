provider "aws" {
  region     = "us-east-1"
}

# Create an SNS topic for notifications
resource "aws_sns_topic" "glacier_notifications" {
  name = "glacier-archive-retrieval-notifications"
}

# Create an S3 Glacier Vault
resource "aws_glacier_vault" "my_archive" {
  name = "MyArchive"

  notification {
    sns_topic = aws_sns_topic.glacier_notifications.arn
    events    = ["ArchiveRetrievalCompleted"]
  }
}