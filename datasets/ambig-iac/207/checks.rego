package autograder_middle

import rego.v1

codebuild_project_valid(codebuild_project, s3_bucket) if {
        some artifact in codebuild_project.expressions.artifacts
        s3_bucket.address in artifact.location.references
        artifact.name
        artifact.type.constant_value == "S3"

        some environment in codebuild_project.expressions.environment
        environment.compute_type
        environment.image
        environment.type

        some source in codebuild_project.expressions.source
        source.type.constant_value == "GITHUB"
        source.location
}

default valid := false

valid if {
        resources := input.configuration.root_module.resources
        some codebuild_project in resources
        codebuild_project.type == "aws_codebuild_project"
        some s3_bucket in resources
        s3_bucket.type == "aws_s3_bucket"
        some security_group in resources
        codebuild_project_valid(codebuild_project, s3_bucket)
}