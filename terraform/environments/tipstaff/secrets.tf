#### This file can be used to store secrets specific to the member account ####
data "aws_secretsmanager_secret" "tipstaff_dev_db_secrets" {
  count = local.application_data.accounts[local.environment] == "development" ? 1 : 0
  arn   = "arn:aws:secretsmanager:eu-west-2:913862848426:secret:tipstaff-dev-db-secrets-8Qc18f"
}

data "aws_secretsmanager_secret" "tactical_products_db_secrets" {
  count = local.application_data.accounts[local.environment] == "development" ? 1 : 0
  arn   = "arn:aws:secretsmanager:eu-west-2:913862848426:secret:tactical-products-db-secrets-ox3sNi"
}

data "aws_secretsmanager_secret_version" "db_credentials" {
  count     = local.application_data.accounts[local.environment] == "development" ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.tipstaff_dev_db_secrets.id
}

data "aws_secretsmanager_secret_version" "dms_source_credentials" {
  count     = local.application_data.accounts[local.environment] == "development" ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.tactical_products_db_secrets.id
}

# Cannot create a secret using the console in pre-production, so trying a different approach
resource "random_string" "username" {
  count   = local.application_data.accounts[local.environment] == "preproduction" ? 1 : 0
  length  = 16
  lower   = true
  upper   = true
  numeric = true
  special = true
}

resource "random_password" "password" {
  count   = local.application_data.accounts[local.environment] == "preproduction" ? 1 : 0
  length  = 16
  lower   = true
  upper   = true
  numeric = true
  special = true
}

resource "aws_secretsmanager_secret" "tipstaff_pre_prod_db_secrets" {
  count                   = local.application_data.accounts[local.environment] == "preproduction" ? 1 : 0
  name                    = "tipstaff-pre-prod-db-secrets"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "secrets_version_username" {
  count         = local.application_data.accounts[local.environment] == "preproduction" ? 1 : 0
  secret_id     = aws_secretsmanager_secret.tipstaff_pre_prod_db_secrets.id
  secret_string = random_string.username.result
}

resource "aws_secretsmanager_secret_version" "secrets_version_password" {
  count         = local.application_data.accounts[local.environment] == "preproduction" ? 1 : 0
  secret_id     = aws_secretsmanager_secret.tipstaff_pre_prod_db_secrets.id
  secret_string = random_password.password.result
}
