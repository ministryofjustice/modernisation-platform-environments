locals {
  name_environment = {
    development   = "dev"
    test          = "test"
    preproduction = "preprod"
    production    = "prod"
  }[local.environment]

  mover_role_names = {
    for entry_id, entry in local.hosted_pickup_entries :
    entry_id => "ihft-${local.name_environment}-hosted-mover-${entry.name_suffix}"
  }

  customer_pickup_role_names = {
    for entry_id, entry in local.hosted_pickup_entries :
    entry_id => "ihft-${local.name_environment}-pickup-reader-${entry.name_suffix}"
  }

  mover_role_arns_by_secret = {
    for entry_id, secret_arn_prefix in local.hosted_pickup_secret_arn_prefixes :
    secret_arn_prefix => module.iam_role_mover[entry_id].arn
  }
}