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

resource "aws_lex_intent" "OrderPizza" {
  name = "OrderPizza"
  description = "Pizza order processing"

  sample_utterances = [
    "I want to order a pizza"
  ]

  slot {
    name                     = "PizzaType"
    description              = "Type of pizza to order"
    slot_constraint          = "Required" 
    slot_type                = "AMAZON.AlphaNumeric"
    priority                 = 1
    value_elicitation_prompt {
      message {
        content             = "What type of pizza would you like?"
        content_type        = "PlainText"
      }
      max_attempts         = 2
    }
  }

  fulfillment_activity {
    type = "ReturnIntent"
  }
}

resource "aws_lex_intent" "CancelOrder" {
  name = "CancelOrder"
  description = "Cancel an order"

  sample_utterances = [
    "I want to cancel my order"
  ]

  fulfillment_activity {
    type = "ReturnIntent"
  }
}

resource "aws_lex_intent" "CheckOrderStatus" {
  name = "CheckOrderStatus"
  description = "Check status of an order"

   sample_utterances = [
    "What is the status of my order"
  ]

  fulfillment_activity {
    type = "ReturnIntent"
  }
}

resource "aws_lex_intent" "ModifyOrder" {
  name = "ModifyOrder"
  description = "Modify an existing order"

  sample_utterances = [
    "I want to change my order"
  ]

  fulfillment_activity {
    type = "ReturnIntent"
  }
}

resource "aws_lex_intent" "HelpOrder" {
  name = "HelpOrder"
  description = "Provide help for ordering"

  sample_utterances = [
    "I need help",
    "Can you help me"
  ]

  fulfillment_activity {
    type = "ReturnIntent"
  }
}

resource "aws_lex_bot" "PizzaOrderBot" {
  abort_statement {
    message {
      content      = "Sorry, I could not assist on this request."
      content_type = "PlainText"
    }
  }

  name = "PizzaOrderBot"
  child_directed = false
  create_version = false
  idle_session_ttl_in_seconds = 600
  process_behavior = "BUILD"
  locale = "en-US"
  voice_id = "Salli"

  clarification_prompt {
    max_attempts = 2

    message {
      content      = "I'm sorry, I didn't understand the request. Can you reformulate?"
      content_type = "PlainText"
    }
  }

  intent {
    intent_name    = aws_lex_intent.OrderPizza.name
    intent_version = aws_lex_intent.OrderPizza.version
  }

  intent {
    intent_name    = aws_lex_intent.CancelOrder.name
    intent_version = aws_lex_intent.CancelOrder.version
  }

  intent {
    intent_name    = aws_lex_intent.CheckOrderStatus.name
    intent_version = aws_lex_intent.CheckOrderStatus.version
  }

  intent {
    intent_name    = aws_lex_intent.ModifyOrder.name
    intent_version = aws_lex_intent.ModifyOrder.version
  }

  intent {
    intent_name    = aws_lex_intent.HelpOrder.name
    intent_version = aws_lex_intent.HelpOrder.version
  }
}