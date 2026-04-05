package terraform.validation

import future.keywords.in

default has_valid_resources = false

# Rule for multiple aws_lex_intent resources
has_valid_lex_intents {
    count([intent | intent := input.planned_values.root_module.resources[_]; intent.type == "aws_lex_intent"; intent.values.name; intent.values.fulfillment_activity; intent.values.follow_up_prompt; intent.values.conclusion_statement == false])
}

# Rule for aws_lex_bot resource with specific arguments
has_valid_lex_bot_instance {
    some i
    resource := input.planned_values.root_module.resources[i]
    resource.type == "aws_lex_bot"
    is_boolean(resource.values.child_directed)
    resource.values.clarification_prompt
    resource.values.abort_statement
    resource.values.name
    # is_boolean(resource.values.create_version)
    # resource.values.description
    # is_boolean(resource.values.detect_sentiment)
    # resource.values.idle_session_ttl_in_seconds
    # resource.values.process_behavior
    # resource.values.voice_id
    # resource.values.locale
}

# Combined rule to ensure all conditions are met
has_valid_resources {
    has_valid_lex_intents
    has_valid_lex_bot_instance
}
