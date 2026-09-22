locals {
  delivery_role_arns_by_secret = {
    for entry_id, secret in data.aws_secretsmanager_secret.file_dispatch :
    secret.arn => module.iam_role_delivery[entry_id].arn
  }
}