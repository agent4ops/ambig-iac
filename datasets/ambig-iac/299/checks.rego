package terraform.validation

# Set default validation states
default is_valid_network_acl = false

# Validate aws_network_acl resources
is_valid_network_acl {
        some i
        network_acl := input.configuration.root_module.resources[i]
        network_acl.type == "aws_network_acl"
        network_acl.name == "example" # Assuming the resource name is "example"

        # Validate linked VPC
        network_acl.expressions.vpc_id.references[0] == "aws_vpc.example.id"
        
        # Check ingress rules for allowing TCP traffic on port 80 from CIDR "10.3.0.0/18"
        ingress := network_acl.expressions.ingress
        ingress.constant_value[0].protocol == "tcp"
        ingress.constant_value[0].rule_no == 100
        ingress.constant_value[0].action == "allow"
       

        # Check egress rules for allowing TCP traffic on port 443 to CIDR "10.3.0.0/18"
        egress := network_acl.expressions.egress
        egress.constant_value[0].protocol == "tcp"
        egress.constant_value[0].rule_no == 200
        egress.constant_value[0].action == "allow"
}
