package vpc_gateway_route
import future.keywords.in

default valid := false

valid {
    some route_resource in input.configuration.root_module.resources
        route_resource.type == "aws_route_table"

        some ig_resource in input.configuration.root_module.resources
        ig_resource.type == "aws_internet_gateway"   
    ig_resource.address in route_resource.expressions.route.references

        some vpc_resource in input.configuration.root_module.resources
        vpc_resource.type == "aws_vpc"
        vpc_resource.address in ig_resource.expressions.vpc_id.references
        vpc_resource.address in route_resource.expressions.vpc_id.references
}