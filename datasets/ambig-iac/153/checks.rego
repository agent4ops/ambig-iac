package vpc_two_subnet
import future.keywords.in

default valid := false

valid {
        some vpc_resource in input.configuration.root_module.resources
        vpc_resource.type == "aws_vpc"

        some subnet1 in input.configuration.root_module.resources
        subnet1.type == "aws_subnet"
        vpc_resource.address in subnet1.expressions.vpc_id.references

        some subnet2 in input.configuration.root_module.resources
        subnet2.type == "aws_subnet"
        vpc_resource.address in subnet2.expressions.vpc_id.references

        not subnet1 == subnet2
}
