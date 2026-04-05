package terraform.validation

default is_valid_configuration = false

# Validate at least one aws_instance with the required arguments
is_valid_instance {
        count(valid_instances) > 0
}

valid_instances[instance] {
        instance := input.configuration.root_module.resources[_]
        instance.type == "aws_instance"
        requited_argument(instance)
}

requited_argument(instance) {
        instance.expressions.launch_template != null
}

requited_argument(instance) {
        instance.expressions.ami != null
        instance.expressions.instance_type != null
}

# Validate aws_lb
is_valid_lb {
        resource := input.configuration.root_module.resources[_]
        resource.type == "aws_lb"
        resource.expressions.load_balancer_type.constant_value == "network"
}

# Validate aws_lb_listener with the required arguments
is_valid_lb_listener {
        resource := input.configuration.root_module.resources[_]
        resource.type == "aws_lb_listener"
        resource.expressions.default_action
        resource.expressions.load_balancer_arn

        valid_protocols := {"TCP", "TLS", "UDP", "TCP_UDP"}
        protocol := resource.expressions.protocol.constant_value

        valid_protocols[protocol]
}

# Validate aws_lb_target_group exists
is_valid_lb_target_group {
        resource := input.configuration.root_module.resources[_]
        resource.type == "aws_lb_target_group"
}

# Validate aws_lb_target_group_attachment with the required arguments
is_valid_lb_target_group_attachment {
        resource := input.configuration.root_module.resources[_]
        resource.type == "aws_lb_target_group_attachment"
        resource.expressions.target_group_arn
        resource.expressions.target_id
}


# Aggregate validation
is_valid_configuration {
        is_valid_lb
        is_valid_lb_listener
        is_valid_lb_target_group_attachment
        is_valid_lb_target_group
        is_valid_instance
}
