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

resource "aws_lex_intent" "order_flowers" {
  name = "OrderFlowers"
  description = "Intent to order a bouquet of flowers for pick up"

  sample_utterances = [
    "I would like to pick up flowers",
    "I would like to order some flowers",
  ]

  slot {
    name                     = "FlowerType"
    description              = "Type of flower to order"
    slot_constraint          = "Required" 
    slot_type                = "AMAZON.AlphaNumeric"
    priority                 = 1

    sample_utterances = ["I would like to get {FlowerType} flower."]

    value_elicitation_prompt {
      message {
        content             = "What type of flower would you like?"
        content_type        = "PlainText"
      }
      max_attempts         = 2
    }
  }

  slot {
    name                     = "PickupDate"
    description              = "Date of flower pickup"
    slot_constraint          = "Required" 
    slot_type                = "AMAZON.DATE"
    priority                 = 2

    value_elicitation_prompt {
      message {
        content             = "When would you like to pickup your flower?"
        content_type        = "PlainText"
      }
      max_attempts         = 2
    }
  }

  confirmation_prompt {
    max_attempts = 2

    message {
      content      = "Okay, your {FlowerType} will be ready for pickup on {PickupDate}.  Does this sound okay?"
      content_type = "PlainText"
    }
  }

  fulfillment_activity {
    type = "ReturnIntent"
  }

  rejection_statement {
    message {
      content      = "Okay, I will not place your order."
      content_type = "PlainText"
    }
  }
}

resource "aws_lex_bot" "order_flowers" {
  name     = "OrderFlowers"
  description = "Bot to order flowers on the behalf of a user"
  locale   = "en-US"
  process_behavior = "BUILD"
  voice_id = "Salli"
  child_directed = false
  create_version = false
  detect_sentiment            = false
  idle_session_ttl_in_seconds = 600

  abort_statement {
    message {
      content_type = "PlainText"
      content      = "Sorry, I am not able to assist at this time"
    }
  }

  clarification_prompt {
    max_attempts = 2

    message {
      content_type = "PlainText"
      content      = "I didn't understand you, what would you like to do?"
    }
  }
  
  intent {
    intent_name    = aws_lex_intent.order_flowers.name
    intent_version = aws_lex_intent.order_flowers.version
  }
}