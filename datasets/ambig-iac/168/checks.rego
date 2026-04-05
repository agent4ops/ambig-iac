package aws_chime_voice_connector
import future.keywords.in

default valid := false

valid {
    some vc in input.configuration.root_module.resources
    vc.type == "aws_chime_voice_connector"
    vc.expressions.require_encryption.constant_value == true

    some vc_streaming in input.configuration.root_module.resources
    vc_streaming.type = "aws_chime_voice_connector_streaming"
    vc_streaming.expressions.data_retention.constant_value == 5
    vc_streaming.expressions.disabled.constant_value == false
    "SNS" in vc_streaming.expressions.streaming_notification_targets.constant_value
    vc.address in vc_streaming.expressions.voice_connector_id.references
}