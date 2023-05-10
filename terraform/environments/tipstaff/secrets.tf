#### This file can be used to store secrets specific to the member account ####

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
  special = false
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
