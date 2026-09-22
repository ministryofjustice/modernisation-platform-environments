locals {
  mover_role_names = {
    for entry_id in keys(local.hosted_pickup_entries) :
    entry_id => "ihft-${local.environment}-hosted-pickup-${entry_id}"
  }

  mover_role_arns_by_secret = {
    for entry_id, secret in data.aws_secretsmanager_secret.file_dispatch :
    secret.arn => module.iam_role_mover[entry_id].arn
  }
}