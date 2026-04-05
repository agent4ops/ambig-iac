package cloud_desktop_high

import rego.v1

default valid := false

instance_valid(instance, ami) if {
	instance.expressions.instance_type
	ami.address in instance.expressions.ami.references
}

backup_plan_valid(backup_plan, backup_vault) if {
	# advanced_backup_setting
	some backup_setting in backup_plan.expressions.advanced_backup_setting
	backup_setting.backup_options

	backup_setting.resource_type.constant_value == "EC2"

	# rule
	some rule in backup_plan.expressions.rule
	backup_vault.address in rule.target_vault_name.references
	rule.schedule.constant_value == "cron(0 0 * * ? *)"
}

backup_selection_valid(backup_selection, backup_plan, instance) if {
	backup_plan.address in backup_selection.expressions.plan_id.references
	instance.address in backup_selection.expressions.resources.references
}

valid if {
	resources := input.configuration.root_module.resources
	some backup_plan in resources
	backup_plan.type == "aws_backup_plan"
	some backup_vault in resources
	backup_vault.type == "aws_backup_vault"
	some backup_selection in resources
	backup_selection.type == "aws_backup_selection"
	some instance in resources
	instance.type == "aws_instance"
	some ami in resources
	ami.type == "aws_ami"

	instance_valid(instance, ami)
	backup_plan_valid(backup_plan, backup_vault)
	backup_selection_valid(backup_selection, backup_plan, instance)
}