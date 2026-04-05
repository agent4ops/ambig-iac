package vpc_net_acl
import future.keywords.in

default valid := false

valid {
        some net_acl_resource in input.configuration.root_module.resources
        net_acl_resource.type == "aws_network_acl"
        net_acl_resource.expressions.egress
        net_acl_resource.expressions.ingress
   
        some vpc_resource in input.configuration.root_module.resources
        vpc_resource.type == "aws_vpc"
        vpc_resource.address in net_acl_resource.expressions.vpc_id.references

        some subnet in input.configuration.root_module.resources
        subnet.type == "aws_subnet"
        vpc_resource.address in subnet.expressions.vpc_id.references
}