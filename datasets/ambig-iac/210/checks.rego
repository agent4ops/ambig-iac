package autograder

import rego.v1

codebuild_project_valid(codebuild_project, s3_bucket, security_group, subnet, vpc) if {
	some artifact in codebuild_project.expressions.artifacts
	s3_bucket.address in artifact.location.references
	artifact.type.constant_value == "S3"
	artifact.name

	some environment in codebuild_project.expressions.environment
	environment.compute_type
	environment.image
	environment.type

	some source in codebuild_project.expressions.source
	source.type.constant_value == "GITHUB"
	source.location

	some vpc_config in codebuild_project.expressions.vpc_config
	security_group.address in vpc_config.security_group_ids.references
	subnet.address in vpc_config.subnets.references
	vpc.address in vpc_config.vpc_id.references
}

security_group_valid(security_group, vpc) if {
	vpc.address in security_group.expressions.vpc_id.references
}

subnet_valid(subnet, vpc) if {
	subnet.expressions.cidr_block
	vpc.address in subnet.expressions.vpc_id.references
}

vpc_valid(vpc) if {
	vpc.expressions.cidr_block
}

default valid := false

valid if {
	resources := input.configuration.root_module.resources
	some codebuild_project in resources
	codebuild_project.type == "aws_codebuild_project"
	some s3_bucket in resources
	s3_bucket.type == "aws_s3_bucket"
	some security_group in resources
	security_group.type == "aws_security_group"
	some subnet in resources
	subnet.type == "aws_subnet"
	some vpc in resources
	vpc.type == "aws_vpc"
	codebuild_project_valid(codebuild_project, s3_bucket, security_group, subnet, vpc)
	security_group_valid(security_group, vpc)
	subnet_valid(subnet, vpc)
	vpc_valid(vpc)
}