module "file_dispatch_configuration" {
  source = "../modules/file-dispatch-configuration"

  environment = local.environment
}

locals {
  push_to_sftp_entries = {
    for entry_id, entry in module.file_dispatch_configuration.entries : entry_id => entry
    if try(entry.action.name, null) == "push-to-sftp"
  }

  delivery_enabled = var.enable_delivery && length(local.push_to_sftp_entries) > 0

  dispatch_secret_arn_prefixes = {
    for entry_id, entry in local.push_to_sftp_entries :
    entry_id => "arn:aws:secretsmanager:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:secret:${local.application_name}/file-dispatch/${entry.identity}${entry.source_prefix}-"
  }

  authorised_destinations_by_secret = {
    for entry_id, arn_prefix in local.dispatch_secret_arn_prefixes :
    arn_prefix => merge({ port = 22 }, local.push_to_sftp_entries[entry_id].action.push_to_sftp)
  }

  source_prefixes_by_secret = {
    for entry_id, arn_prefix in local.dispatch_secret_arn_prefixes :
    arn_prefix => "${local.push_to_sftp_entries[entry_id].identity}${local.push_to_sftp_entries[entry_id].source_prefix}"
  }

  credential_arns_by_secret = {
    for entry_id, arn_prefix in local.dispatch_secret_arn_prefixes :
    arn_prefix => module.secrets_private_key[entry_id].secret_arn
  }
}