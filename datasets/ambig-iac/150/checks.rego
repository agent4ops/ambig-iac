package vpc_ipv6
import future.keywords.in

default valid := false

valid {
	some changed_resource in input.resource_changes
	changed_resource.type == "aws_vpc"
	"create" in changed_resource.change.actions
	args := changed_resource.change.after
	net.cidr_is_valid(args.cidr_block)
	args.assign_generated_ipv6_cidr_block == true
}
