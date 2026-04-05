package aws_chime_voice_connector
import future.keywords.in

default valid := false

valid {
    some vc in input.configuration.root_module.resources
    vc.type == "aws_chime_voice_connector"
    vc.expressions.require_encryption.constant_value == true

    some vc_logging in input.configuration.root_module.resources
    vc_logging.type = "aws_chime_voice_connector_logging"
    vc_logging.expressions.enable_media_metric_logs.constant_value == true
    vc.address in vc_logging.expressions.voice_connector_id.references
}