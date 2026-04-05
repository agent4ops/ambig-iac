provider "aws" {
region = "us-east-1" # Change to your desired AWS region
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

ttl {
attribute_name = "custom_ttl_attribute" # Replace with your custom TTL attribute name
enabled = true # Set to true to enable TTL on the table
}
}