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


resource "aws_lex_bot" "KidsPizzaOrderBot" {
  child_directed = true
  name           = "KidsPizzaOrderBot"
  process_behavior = "BUILD"
  idle_session_ttl_in_seconds = 300
  locale = "en-US"
  voice_id = "Salli"

  abort_statement {
    message {
      content      = "I'm sorry, I can't assist further on this."
      content_type = "PlainText"
    }
  }

  clarification_prompt {
    max_attempts = 1
    message {
      content      = "I'm sorry, could you please repeat that?"
      content_type = "PlainText"
    }
  }

  intent {
    intent_name    = aws_lex_intent.PizzaOrder.name
    intent_version = aws_lex_intent.PizzaOrder.version
  }

  intent {
    intent_name    = aws_lex_intent.CancelOrder.name
    intent_version = aws_lex_intent.CancelOrder.version
  }

  intent {
    intent_name    = aws_lex_intent.Appreciation.name
    intent_version = aws_lex_intent.Appreciation.version
  }
}

resource "aws_lex_intent" "PizzaOrder" {
  name = "PizzaOrder"
  description = "Intent for ordering pizza"

  sample_utterances = [
    "I would like to order a pizza",
  ]

  fulfillment_activity {
    type = "ReturnIntent"
  }
}

resource "aws_lex_intent" "CancelOrder" {
  name = "CancelOrder"
  description = "Intent for canceling pizza order"

  sample_utterances = [
    "I would like to cancel my order",
  ]

  fulfillment_activity {
    type = "ReturnIntent"
  }
}

resource "aws_lex_intent" "Appreciation" {
  name = "Appreciation"
  description = "Intent for appreciating the service"

  sample_utterances = [
    "I appreciate your service",
  ]

  fulfillment_activity {
    type = "ReturnIntent"
  }
}