package terraform.validation

# Set default validation states
default is_valid_vpcs = false
default is_valid_vpc_peering_connection = false

# Validate aws_vpc resources
is_valid_vpcs {
    # Validate the first VPC named "peer"
    peer_vpc := input.configuration.root_module.resources[_]
    peer_vpc.type == "aws_vpc"
    peer_vpc.name == "peer"
    peer_vpc.expressions.cidr_block.constant_value == "10.0.0.0/24"

    # Validate the second VPC named "base"
    base_vpc := input.configuration.root_module.resources[_]
    base_vpc.type == "aws_vpc"
    base_vpc.name == "base"
    base_vpc.expressions.cidr_block.constant_value == "10.1.0.0/24"

    # Ensure different VPCs
    peer_vpc != base_vpc
}

# Validate aws_vpc_peering_connection resource
is_valid_vpc_peering_connection {
    some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_vpc_peering_connection"
    resource.name == "pike"
    # Ensure connection between "peer" and "base" VPCs
    resource.expressions.peer_vpc_id.references[0] == "aws_vpc.peer.id"
    resource.expressions.vpc_id.references[0] == "aws_vpc.base.id"
    # Check for the specific tag indicating its purpose
    resource.expressions.tags.constant_value["pike"] == "permissions"
}