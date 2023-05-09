#### This file can be used to store secrets specific to the member account ####

data "aws_secretsmanager_secret" "tactical_products_db_secrets" {
  count = local.is-development ? 1 : 0
  arn   = "arn:aws:secretsmanager:eu-west-2:913862848426:secret:tactical-products-db-secrets-ox3sNi"
}

data "aws_secretsmanager_secret_version" "dms_source_credentials" {
  count     = local.is-development ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.tactical_products_db_secrets[0].id
}

resource "random_string" "username" {
  length  = 16
  lower   = true
  upper   = true
  numeric = false
  special = false
}

resource "random_password" "password" {
  length  = 16
  lower   = true
  upper   = true
  numeric = true
  special = true
}

resource "aws_secretsmanager_secret" "tipstaff_db_secrets" {
  name                    = "tipstaff-db-secrets"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id     = aws_secretsmanager_secret.tipstaff_db_secrets.id
  secret_string = jsonencode({ "TIPSTAFF_DB_USERNAME" : "${random_string.username.result}", "TIPSTAFF_DB_PASSWORD" : "${random_password.password.result}" })
}

resource "aws_secretsmanager_secret" "tactical_products_db_secrets" {
  name                    = "tipstaff-tactical-products-db-secrets"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "tactical_products_rds_credentials" {
  secret_id     = aws_secretsmanager_secret.tactical_products_db_secrets.id
  secret_string = jsonencode({ "" : "", "" : "" })
}
