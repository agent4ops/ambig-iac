provider "aws" {
region = "us-east-1" # Change this to your desired AWS region
}

resource "aws_dynamodb_table" "example" {
name = "your-dynamodb-table-name"
billing_mode = "PAY_PER_REQUEST" # Or "PROVISIONED" if you prefer provisioned capacity
hash_key = "id"
attribute {
name = "id"
type = "S"
}

# Define other table settings as needed

stream_enabled = true # Enable streams
stream_view_type = "NEW_AND_OLD_IMAGES" # Choose the appropriate stream view type
}