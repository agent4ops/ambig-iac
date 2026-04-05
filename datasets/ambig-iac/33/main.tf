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

resource "aws_lex_intent" "order_pizza_intent" {
  name                       = "OrderPizzaIntent"
  description                = "To order a pizza"
  
  sample_utterances = [
    "I would like to pick up a pizza",
    "I would like to order some pizzas",
  ]

  fulfillment_activity {
    type = "ReturnIntent"
  }

  conclusion_statement {
    message {
      content              = "Your pizza order has been received."
      content_type         = "PlainText"
    }
  } 
}

resource "aws_lex_bot" "pizza_ordering_bot" {
  name                     = "PizzaOrderingBot"
  description              = "Bot to order pizzas"
  voice_id                 = "Joanna"
  idle_session_ttl_in_seconds = "300"
  child_directed           = false
  enable_model_improvements = true
  nlu_intent_confidence_threshold = 0.5
  locale                  = "en-US"
  process_behavior        = "BUILD"

  clarification_prompt {
    message {
      content      = "I didn't understand you, what type of pizza would you like to order?"
      content_type = "PlainText"
    }
    max_attempts = 5
  }

  abort_statement {
    message {
      content      = "Sorry, I am unable to assist at the moment."
      content_type = "PlainText"
    }
  }

  intent {
    intent_name    = aws_lex_intent.order_pizza_intent.name
    intent_version = aws_lex_intent.order_pizza_intent.version
  }
}

