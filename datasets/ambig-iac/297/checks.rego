package terraform.validation

# Set default validation states
default is_valid_network_acl = false

# Validate aws_default_network_acl resources
is_valid_network_acl {
        some i
        network_acl := input.configuration.root_module.resources[i]
        network_acl.type == "aws_default_network_acl"
        
        # Check ingress rules for unrestricted access
        ingress := network_acl.expressions.ingress
        ingress[0].protocol.constant_value == -1
    ingress[0].action.constant_value == "allow"
        ingress[0].cidr_block.constant_value == "0.0.0.0/0"
        ingress[0].from_port.constant_value == 0
        ingress[0].to_port.constant_value == 0

        # Check egress rules for unrestricted access
        egress := network_acl.expressions.egress
        egress[0].protocol.constant_value == -1
        egress[0].action.constant_value == "allow"
        egress[0].cidr_block.constant_value == "0.0.0.0/0"
        egress[0].from_port.constant_value == 0
        egress[0].to_port.constant_value == 0

}
