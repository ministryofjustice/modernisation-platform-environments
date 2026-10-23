locals {
  aws_accounts = jsondecode(
    data.aws_secretsmanager_secret_version.aws_accounts.secret_string
  ).accounts
}
