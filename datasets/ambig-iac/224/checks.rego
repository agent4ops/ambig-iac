package terraform.validation

default is_valid_db_option_group = false

# Regex pattern to match "11", "11.0", "11.00", etc.
pattern := `^11(\.0+)?$`

# Validate aws_db_option_group resource
is_valid_db_option_group {
    some i
    resource := input.configuration.root_module.resources[i]
    resource.type == "aws_db_option_group"
    resource.expressions.engine_name.constant_value == "sqlserver-ee"
    major_engine_version_value := resource.expressions.major_engine_version.constant_value
    is_valid_version(major_engine_version_value)
    resource.expressions.name.constant_value == "option-group-pike"

    # Ensure options for SQLSERVER_AUDIT and TDE are included
    sqlserver_audit_option := resource.expressions.option[_]
    sqlserver_audit_option.option_name.constant_value == "SQLSERVER_AUDIT"
    tde_option := resource.expressions.option[_]
    tde_option.option_name.constant_value == "TDE"

    # Ensure specific settings for IAM_ROLE_ARN and S3_BUCKET_ARN are included under SQLSERVER_AUDIT option
    iam_role_arn_setting := sqlserver_audit_option.option_settings[_]
    iam_role_arn_setting.name.constant_value == "IAM_ROLE_ARN"
    iam_role_arn_setting.value != null
    s3_bucket_arn_setting := sqlserver_audit_option.option_settings[_]
    s3_bucket_arn_setting.name.constant_value == "S3_BUCKET_ARN"
    s3_bucket_arn_setting.value != null

}

# Helper function to check if the version matches the regex pattern
is_valid_version(version) {
    regex.match(pattern, sprintf("%v", [version]))
}