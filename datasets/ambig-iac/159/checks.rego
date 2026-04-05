package aws_neptune_cluster
import future.keywords.in

default valid := false

valid {
    some vpc in input.configuration.root_module.resources
    vpc.type == "aws_vpc"

    some subnet1 in input.configuration.root_module.resources
    subnet1.type == "aws_subnet"
    vpc.address in subnet1.expressions.vpc_id.references
    
    some subnet2 in input.configuration.root_module.resources
    subnet2.type == "aws_subnet"
    vpc.address in subnet2.expressions.vpc_id.references
    
    not subnet1 == subnet2
    
    some subnet_group in input.configuration.root_module.resources
    subnet_group.type == "aws_neptune_subnet_group"
    subnet1.address in subnet_group.expressions.subnet_ids.references
    subnet2.address in subnet_group.expressions.subnet_ids.references
}
