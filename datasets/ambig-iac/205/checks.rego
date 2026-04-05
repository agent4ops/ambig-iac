package autograder_high

import rego.v1

codebuild_project_valid(codebuild_project) if {
        some artifact in codebuild_project.expressions.artifacts
        artifact.location
        artifact.name
        artifact.type
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
        some security_group in resources
        codebuild_project_valid(codebuild_project)
}