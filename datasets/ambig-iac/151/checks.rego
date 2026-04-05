package vpc_netgate_basic
import future.keywords.in

default valid := false

valid {
	some ig_resource in input.configuration.root_module.resources
	ig_resource.type == "aws_internet_gateway"

	some vpc_resource in input.configuration.root_module.resources
	vpc_resource.type == "aws_vpc"
	vpc_resource.address in ig_resource.expressions.vpc_id.references
}