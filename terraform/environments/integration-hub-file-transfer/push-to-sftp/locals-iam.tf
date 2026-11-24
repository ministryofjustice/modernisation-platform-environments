locals {
  delivery_resource_names = {
    for entry_id, entry in local.push_to_sftp_entries :
    entry_id => "${local.environment}-${local.component_name}-${entry.name_suffix}"
  }

  modernisation_platform_developer_role_arn_pattern = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/*/AWSReservedSSO_modernisation-platform-developer_*"
}