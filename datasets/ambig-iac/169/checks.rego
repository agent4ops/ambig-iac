package aws_chime_voice_connector
import future.keywords.in

default valid := false

valid {
    some vc in input.configuration.root_module.resources
    vc.type == "aws_chime_voice_connector"
    vc.expressions.require_encryption.constant_value == true

    some vc_streaming in input.configuration.root_module.resources
    vc_streaming.type = "aws_chime_voice_connector_streaming"
    vc.address in vc_streaming.expressions.voice_connector_id.references
}