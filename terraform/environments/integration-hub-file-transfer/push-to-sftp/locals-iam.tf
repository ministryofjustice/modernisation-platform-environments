locals {
  name_environment = {
    development   = "dev"
    test          = "test"
    preproduction = "preprod"
    production    = "prod"
  }[local.environment]

  delivery_resource_names = {
    for entry_id, entry in local.push_to_sftp_entries :
    entry_id => "ihft-${local.name_environment}-push-to-sftp-${entry.name_suffix}"
  }

  delivery_role_arns_by_secret = {
    for entry_id, arn_prefix in local.dispatch_secret_arn_prefixes :
    arn_prefix => module.iam_role_delivery[entry_id].arn
  }
}