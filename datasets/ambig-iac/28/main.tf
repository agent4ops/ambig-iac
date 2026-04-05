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


resource "aws_lex_bot" "pizza_order_bot" {
  name = "PizzaOrderBot"
  description = "Pizza order bot"
  idle_session_ttl_in_seconds = 600
  create_version = false
  child_directed = false

  abort_statement {
    message {
      content = "Sorry, I am not able to assist."
      content_type = "PlainText"
    }
  }

  clarification_prompt {
    max_attempts = 2
    message {
      content = "I'm sorry, I didn't understand that. Can you try again?"
      content_type = "PlainText"
    }
  }

  intent {
    intent_name = aws_lex_intent.OrderPizzaIntent.name
    intent_version = aws_lex_intent.OrderPizzaIntent.version
  }
}

resource "aws_lex_intent" "OrderPizzaIntent" {
  name = "OrderPizzaIntent"
  create_version = true

  sample_utterances = [
    "I would like to pick up a pizza",
    "I would like to order some pizzas",
  ]

  slot {
    name = "PizzaType"
    description = "Type of pizza to order"
    priority = 1  # must be in [1, 100]
    slot_type = aws_lex_slot_type.PizzaType.name
    slot_type_version = aws_lex_slot_type.PizzaType.version
    slot_constraint = "Required"

    sample_utterances = ["I want a {PizzaType} pizza.", "A {PizzaType} pizza please."]

    value_elicitation_prompt {
      max_attempts = 2
      message {
        content = "What type of pizza would you like to order?"
        content_type = "PlainText"
      }
    }
  }

  confirmation_prompt {
    max_attempts = 2
    message {
      content = "So, you would like to order a pizza. Is that correct?"
      content_type = "PlainText"
    }
  }

  rejection_statement {
    message {
        content = "Sorry, I don't know how to help then"
        content_type = "PlainText"
      }
    }

  follow_up_prompt {
    prompt {
      max_attempts = 2
      message {
        content = "Would you like anything else with your order?"
        content_type = "PlainText"
      }
    }
    rejection_statement {
      message {
        content = "OK, Your pizza is on its way."
        content_type = "PlainText"
      }
    }
  }

  fulfillment_activity {
    type = "ReturnIntent"
  }
}

resource "aws_lex_slot_type" "PizzaType" {
  create_version = true
  description = "Types of pizza available to order"
  name = "PizzaTypes"
  enumeration_value {
    value = "Margherita"
  }
  enumeration_value {
    value = "Pepperoni"
  }
}