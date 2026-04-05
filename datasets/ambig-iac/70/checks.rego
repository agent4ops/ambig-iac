package terraform.validation

default has_aws_eks_identity_provider_config_example = false

has_aws_eks_identity_provider_config_example {
    identity_provider_config := input.planned_values.root_module.resources[_]
    identity_provider_config.type == "aws_eks_identity_provider_config"
    identity_provider_config.values.cluster_name == input.planned_values.root_module.resources[_].values.name
    
    # Check OIDC configuration
    identity_provider_config.values.oidc[_].client_id != null
    identity_provider_config.values.oidc[_].identity_provider_config_name != null
    identity_provider_config.values.oidc[_].issuer_url != null
}