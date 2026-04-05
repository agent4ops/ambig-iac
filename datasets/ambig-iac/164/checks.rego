package aws_chime_voice_connector
import future.keywords.in

default valid := false
default connectors_valid := false

valid {
    connectors_valid
}

connectors_valid {
    some vc1 in input.configuration.root_module.resources
    vc1.type == "aws_chime_voice_connector"
    vc1.expressions.require_encryption.constant_value == true

    some vc2 in input.configuration.root_module.resources
    vc2.type == "aws_chime_voice_connector"
    vc2.expressions.require_encryption.constant_value == true

    not vc1 == vc2
    
    some vcgroup in input.configuration.root_module.resources
    vcgroup.type == "aws_chime_voice_connector_group"

    some connector1 in vcgroup.expressions.connector
    vc1.address in connector1.voice_connector_id.references
    some connector2 in vcgroup.expressions.connector
    vc2.address in connector2.voice_connector_id.references
    
    not connector1 == connector2
    
    connector1.priority.constant_value > connector2.priority.constant_value    
}

connectors_valid {
        some vc1 in input.configuration.root_module.resources
    vc1.type == "aws_chime_voice_connector"
    vc1.expressions.require_encryption.constant_value == true

    some vc2 in input.configuration.root_module.resources
    vc2.type == "aws_chime_voice_connector"
    vc2.expressions.require_encryption.constant_value == true

    not vc1 == vc2
    
    some vcgroup in input.configuration.root_module.resources
    vcgroup.type == "aws_chime_voice_connector_group"

    some connector1 in vcgroup.expressions.connector
    vc1.address in connector1.voice_connector_id.references
    some connector2 in vcgroup.expressions.connector
    vc2.address in connector2.voice_connector_id.references
    
    not connector1 == connector2
    
    connector1.priority.constant_value < connector2.priority.constant_value    
}