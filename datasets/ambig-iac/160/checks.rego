package aws_neptune_cluster
import future.keywords.in

default valid := false

# See for more info: https://docs.aws.amazon.com/neptune/latest/userguide/parameter-groups.html
default cluster_parameter_group_valid := false
default instance_parameter_group_valid := false

valid {
        some cluster in input.configuration.root_module.resources
        cluster.type == "aws_neptune_cluster"
        cluster_parameter_group_valid

        some instance in input.configuration.root_module.resources
        instance.type == "aws_neptune_cluster_instance"
        cluster.address in instance.expressions.cluster_identifier.references
        instance_parameter_group_valid
}

cluster_parameter_group_valid {
        some cluster in input.configuration.root_module.resources
        cluster.type == "aws_neptune_cluster"

        some cluster_parameter_group in input.configuration.root_module.resources
        cluster_parameter_group.type == "aws_neptune_cluster_parameter_group"
        cluster_parameter_group.address in cluster.expressions.neptune_cluster_parameter_group_name.references

        cluster.expressions.engine_version.constant_value < "1.2.0.0"
        cluster_parameter_group.expressions.family.constant_value == "neptune1"
}

cluster_parameter_group_valid {
        some cluster in input.configuration.root_module.resources
        cluster.type == "aws_neptune_cluster"

        some cluster_parameter_group in input.configuration.root_module.resources
        cluster_parameter_group.type == "aws_neptune_cluster_parameter_group"
        cluster_parameter_group.address in cluster.expressions.neptune_cluster_parameter_group_name.references

        cluster.expressions.engine_version.constant_value >= "1.2.0.0"
        cluster_parameter_group.expressions.family.constant_value == "neptune1.2"
}

cluster_parameter_group_valid {
        some cluster in input.configuration.root_module.resources
        cluster.type == "aws_neptune_cluster"

        some cluster_parameter_group in input.configuration.root_module.resources
        cluster_parameter_group.type == "aws_neptune_cluster_parameter_group"
        cluster_parameter_group.address in cluster.expressions.neptune_cluster_parameter_group_name.references

        not cluster.expressions.engine_version.constant_value
        cluster_parameter_group.expressions.family.constant_value == "neptune1.2"
}

instance_parameter_group_valid {
        some instance in input.configuration.root_module.resources
        instance.type == "aws_neptune_cluster_instance"

        some instance_parameter_group in input.configuration.root_module.resources
        instance_parameter_group.type == "aws_neptune_parameter_group"
        instance_parameter_group.address in instance.expressions.neptune_parameter_group_name.references

        instance.expressions.engine_version.constant_value < "1.2.0.0"
        instance_parameter_group.expressions.family.constant_value == "neptune1"
}

instance_parameter_group_valid {
        some instance in input.configuration.root_module.resources
        instance.type == "aws_neptune_cluster_instance"

        some instance_parameter_group in input.configuration.root_module.resources
        instance_parameter_group.type == "aws_neptune_parameter_group"
        instance_parameter_group.address in instance.expressions.neptune_parameter_group_name.references

        instance.expressions.engine_version.constant_value >= "1.2.0.0"
        instance_parameter_group.expressions.family.constant_value == "neptune1.2"
}

instance_parameter_group_valid {
        some instance in input.configuration.root_module.resources
        instance.type == "aws_neptune_cluster_instance"

        some instance_parameter_group in input.configuration.root_module.resources
        instance_parameter_group.type == "aws_neptune_parameter_group"
        instance_parameter_group.address in instance.expressions.neptune_parameter_group_name.references

        not instance.expressions.engine_version.constant_value
        instance_parameter_group.expressions.family.constant_value == "neptune1.2"
}