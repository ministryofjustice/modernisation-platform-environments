output "recipients" {
  description = "Approved clean-prefix and assigned-group mappings for Slack pickup."
  value       = local.recipients_by_environment[var.environment]
}

output "assigned_groups" {
  description = "Existing Transfer web app group IDs, managed by the root state."
  value       = module.transfer_identity.groups
}
