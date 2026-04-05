package vpc_instance
import future.keywords.in

default valid := false

valid {
        some vpc_resource in input.configuration.root_module.resources
        vpc_resource.type == "aws_vpc"

        some subnet in input.configuration.root_module.resources
        subnet.type == "aws_subnet"
        vpc_resource.address in subnet.expressions.vpc_id.references

    some ami in input.configuration.root_module.resources
    ami.type == "aws_ami"
    some filter in ami.expressions.filter
    some ami_name in filter.values.constant_value
    ami_name == "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"

    some instance in input.configuration.root_module.resources
    instance.type == "aws_instance"
    ami.address in instance.expressions.ami.references
    subnet.address in instance.expressions.subnet_id.references
}
