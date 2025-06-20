data "aws_secretsmanager_secret" "environment_management" {
  provider = aws.modernisation-platform
  name     = "environment_management"
}

data "aws_secretsmanager_secret_version" "environment_management" {
  provider  = aws.modernisation-platform
  secret_id = data.aws_secretsmanager_secret.environment_management.id
}

locals {
  environment_management_accounts = jsondecode(data.aws_secretsmanager_secret_version.environment_management.secret_string)
  core_logging_account_id         = local.environment_management_accounts["core-logging-production"]
}
