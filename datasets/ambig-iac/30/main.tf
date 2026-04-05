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
  region  = "us-east-1"
}

resource "aws_lex_intent" "BookTrip" {
  description    = "Book a trip"
  name           = "BookTrip"

  sample_utterances = [
    "I want to book a trip",
    "I would like to book a trip",
  ]

  fulfillment_activity {
    type = "ReturnIntent"
  }
}

resource "aws_lex_bot" "BookTripBot" {
  description                   = "Bot for booking trips"
  idle_session_ttl_in_seconds   = 600
  locale                        = "en-US"
  name                          = "BookTripBot"
  process_behavior              = "BUILD"
  voice_id                      = "Salli"
  detect_sentiment = false
  enable_model_improvements = true
  nlu_intent_confidence_threshold = 0
  child_directed                = false

  abort_statement {
    message {
      content      = "Sorry, I cannot assist you to book the trip right now."
      content_type = "PlainText"
    }
  }
  
  clarification_prompt {
    max_attempts = 3

    message {
      content      = "I'm sorry, I didn't understand. Could you please repeat that?"
      content_type = "PlainText"
    }
  }

  intent {
    intent_name    = aws_lex_intent.BookTrip.name
    intent_version = aws_lex_intent.BookTrip.version
  }
}