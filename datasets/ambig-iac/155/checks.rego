package vpc_peer_connect
import future.keywords.in

default valid := false        

valid {
        some vpc_resource1 in input.configuration.root_module.resources
        vpc_resource1.type == "aws_vpc"
    
    some vpc_resource2 in input.configuration.root_module.resources
        vpc_resource2.type == "aws_vpc"

    not vpc_resource1 == vpc_resource2
    
        some peer_connection_resource in input.configuration.root_module.resources
        peer_connection_resource.type == "aws_vpc_peering_connection"
    vpc_resource1.address in peer_connection_resource.expressions.vpc_id.references
    vpc_resource2.address in peer_connection_resource.expressions.peer_vpc_id.references
}