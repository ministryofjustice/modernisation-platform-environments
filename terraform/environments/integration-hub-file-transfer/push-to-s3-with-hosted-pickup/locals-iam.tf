locals {
  mover_role_names = {
    for entry_id in keys(local.hosted_pickup_entries) :
    entry_id => "ihft-${local.environment}-hosted-pickup-${entry_id}"
  }

  customer_pickup_role_names = {
    for entry_id in keys(local.hosted_pickup_entries) :
    entry_id => "ihft-${local.environment}-hosted-pickup-customer-${entry_id}"
  }

  mover_role_arns_by_secret = {
    for entry_id, secret_arn_prefix in local.hosted_pickup_secret_arn_prefixes :
    secret_arn_prefix => module.iam_role_mover[entry_id].arn
  }
}