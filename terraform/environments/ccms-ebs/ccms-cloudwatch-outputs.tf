output "aws_ssm_document_cloud_watch_agent_description" {
  description = "aws_ssm_document cloud_watch_agent description"
  value       = aws_ssm_document.cloud_watch_agent.description
}

#

output "aws_cloudwatch_log_group_groups_arn" {
  description = "aws_cloudwatch_log_group groups arn"
  value       = try(aws_cloudwatch_log_group.groups[*].arn, "None")
}

#

output "aws_ssm_parameter_cw_agent_config_arn" {
  description = "aws_ssm_parameter cw_agent_config arn"
  value       = aws_ssm_parameter.cw_agent_config.arn
}

#

output "aws_ssm_association_update_ssm_agent_arn" {
  description = "aws_ssm_association update_ssm_agent arn"
  value       = aws_ssm_association.update_ssm_agent.arn
}

output "aws_ssm_association_update_ssm_agent_targets" {
  description = "aws_ssm_association update_ssm_agent targets"
  value       = aws_ssm_association.update_ssm_agent.targets
}

output "aws_ssm_association_update_ssm_agent_name" {
  description = "aws_ssm_association update_ssm_agent name"
  value       = aws_ssm_association.update_ssm_agent.name
}

#

output "aws_iam_policy_cloudwatch_datasource_policy_arn" {
  description = "aws_iam_policy cloudwatch_datasource_policy arn"
  value       = aws_iam_policy.cloudwatch_datasource_policy.arn
}

output "aws_iam_policy_cloudwatch_datasource_policy_policy" {
  description = "aws_iam_policy cloudwatch_datasource_policy policy"
  value       = aws_iam_policy.cloudwatch_datasource_policy.policy
}

#

# This resource exports no additional attributes.
#output "aws_iam_role_policy_attachment_cloudwatch_datasource_policy_attach" {
#  value = aws_iam_role_policy_attachment.cloudwatch_datasource_policy_attach
#}
