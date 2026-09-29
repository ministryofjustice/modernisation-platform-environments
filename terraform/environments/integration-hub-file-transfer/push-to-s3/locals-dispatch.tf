module "file_dispatch_configuration" {
  source = "../modules/file-dispatch-configuration"

  environment = local.environment
}

locals {
  file_dispatch_secret_name_prefix = "${local.application_name}/file-dispatch/"

  push_to_s3_entries = {
    for entry_id, entry in module.file_dispatch_configuration.entries : entry_id => entry
    if try(entry.action.name, null) == "push-to-s3"
  }

  push_to_s3_secret_names = {
    for entry_id, entry in local.push_to_s3_entries :
    entry_id => "${local.file_dispatch_secret_name_prefix}${entry.identity}${entry.source_prefix}"
  }

  push_to_s3_secret_arn_prefixes = {
    for entry_id, secret_name in local.push_to_s3_secret_names :
    entry_id => "arn:aws:secretsmanager:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:secret:${secret_name}-"
  }

  authorised_destinations_by_secret = {
    for entry_id, secret_arn_prefix in local.push_to_s3_secret_arn_prefixes :
    secret_arn_prefix => {
      bucket             = local.push_to_s3_entries[entry_id].action.push_to_s3.bucket_id
      region             = try(local.push_to_s3_entries[entry_id].action.push_to_s3.bucket_region, "eu-west-2")
      destination_prefix = local.push_to_s3_entries[entry_id].action.push_to_s3.destination_prefix
      kms_key_arn        = local.push_to_s3_entries[entry_id].action.push_to_s3.kms_key_arn
    }
  }

  source_prefixes_by_secret = {
    for entry_id, secret_arn_prefix in local.push_to_s3_secret_arn_prefixes :
    secret_arn_prefix => "${local.push_to_s3_entries[entry_id].identity}${local.push_to_s3_entries[entry_id].source_prefix}"
  }
}