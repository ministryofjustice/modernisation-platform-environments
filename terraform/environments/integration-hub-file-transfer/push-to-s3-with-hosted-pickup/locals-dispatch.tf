module "file_dispatch_configuration" {
  source = "../modules/file-dispatch-configuration"

  environment = local.environment
}

locals {
  file_dispatch_secret_name_prefix = "${local.application_name}/file-dispatch/"

  hosted_pickup_entries = {
    for entry_id, entry in module.file_dispatch_configuration.entries : entry_id => entry
    if try(entry.action.name, null) == "push-to-s3-with-hosted-pickup"
  }

  hosted_pickup_secret_names = {
    for entry_id, entry in local.hosted_pickup_entries :
    entry_id => "${local.file_dispatch_secret_name_prefix}${entry.identity}${entry.source_prefix}"
  }

  source_prefixes_by_secret = {
    for entry_id, secret in data.aws_secretsmanager_secret.file_dispatch :
    secret.arn => "${local.hosted_pickup_entries[entry_id].identity}${local.hosted_pickup_entries[entry_id].source_prefix}"
  }

  authorised_destinations_by_secret = {
    for entry_id, secret in data.aws_secretsmanager_secret.file_dispatch :
    secret.arn => {
      bucket             = local.hosted_bucket_names[entry_id]
      region             = "eu-west-2"
      destination_prefix = local.hosted_pickup_entries[entry_id].action.push_to_s3_with_hosted_pickup.destination_prefix
      retention_days     = local.hosted_pickup_entries[entry_id].action.push_to_s3_with_hosted_pickup.retention_days
      kms_key_arn        = module.kms_hosted_pickup[entry_id].key_arn
    }
  }
}