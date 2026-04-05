package terraform

default ami_latest_amazon_linux_2 = false

ami_latest_amazon_linux_2 {
    resource := input.configuration.root_module.resources[_]
    resource.type == "aws_ami"
    resource.name == "latest_amazon_linux_2"
    resource.expressions.filter[_].name.constant_value == "name"
    resource.expressions.filter[_].values.constant_value[_] == "amzn2-ami-hvm-*-x86_64-gp2"
    resource.expressions.most_recent.constant_value == true
    resource.expressions.owners.constant_value[_] == "amazon"
}