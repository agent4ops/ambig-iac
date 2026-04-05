package aws_neptune_cluster
import future.keywords.in

default neptune_cluster_valid := false
default cluster_parameter_group_valid := false

neptune_cluster_valid {
    some cluster in input.configuration.root_module.resources
    cluster.type == "aws_neptune_cluster"
    cluster_parameter_group_valid
}

cluster_parameter_group_valid {
    some cluster in input.configuration.root_module.resources
    cluster.type == "aws_neptune_cluster"

    some cluster_parameter_group in input.configuration.root_module.resources
    cluster_parameter_group.type == "aws_neptune_cluster_parameter_group"
    cluster_parameter_group.address in cluster.expressions.neptune_cluster_parameter_group_name.references

    # See for more info: https://docs.aws.amazon.com/neptune/latest/userguide/parameter-groups.html
    cluster.expressions.engine_version.constant_value < "1.2.0.0"
    cluster_parameter_group.expressions.family.constant_value == "neptune1"   
}

cluster_parameter_group_valid {
    some cluster in input.configuration.root_module.resources
    cluster.type == "aws_neptune_cluster"

    some cluster_parameter_group in input.configuration.root_module.resources
    cluster_parameter_group.type == "aws_neptune_cluster_parameter_group"
    cluster_parameter_group.address in cluster.expressions.neptune_cluster_parameter_group_name.references

    # See for more info: https://docs.aws.amazon.com/neptune/latest/userguide/parameter-groups.html
    cluster.expressions.engine_version.constant_value >= "1.2.0.0"
    cluster_parameter_group.expressions.family.constant_value == "neptune1.2"   
}

cluster_parameter_group_valid {
    some cluster in input.configuration.root_module.resources
    cluster.type == "aws_neptune_cluster"
    
    some cluster_parameter_group in input.configuration.root_module.resources
    cluster_parameter_group.type == "aws_neptune_cluster_parameter_group"
    cluster_parameter_group.address in cluster.expressions.neptune_cluster_parameter_group_name.references
    
    # See for more info: https://docs.aws.amazon.com/neptune/latest/userguide/parameter-groups.html
    not cluster.expressions.engine_version.constant_value # defaults as latest version
    cluster_parameter_group.expressions.family.constant_value == "neptune1.2"   
}