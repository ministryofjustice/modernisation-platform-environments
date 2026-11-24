module "file_dispatch_configuration" {
  source = "../modules/file-dispatch-configuration"

  environment = local.environment
}

locals {
  sftp_key_secret_prefix = "sftp-keys"

  push_to_sftp_entries = {
    for entry_id, entry in module.file_dispatch_configuration.entries : entry_id => entry
    if try(entry.action.name, null) == "push-to-sftp"
  }

  push_to_sftp_secret_arn_prefixes = {
    for entry_id, entry in local.push_to_sftp_entries :
    entry_id => "arn:aws:secretsmanager:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:secret:${local.application_name}/file-dispatch/${entry.identity}${entry.source_prefix}-"
  }

  sftp_destinations_by_secret = {
    for entry_id, secret_arn_prefix in local.push_to_sftp_secret_arn_prefixes :
    secret_arn_prefix => merge({ port = 22 }, local.push_to_sftp_entries[entry_id].action.push_to_sftp)
  }
}