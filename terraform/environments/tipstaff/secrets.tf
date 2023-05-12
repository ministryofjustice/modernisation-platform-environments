#### This file can be used to store secrets specific to the member account ####

resource "random_password" "password" {
  length  = 16
  lower   = true
  upper   = true
  numeric = true
  special = false
}

// Secrets for the tipstaff database on the modernisation platform
resource "aws_secretsmanager_secret" "tipstaff_db_secrets" {
  name                    = "tipstaff-db-secrets"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id     = aws_secretsmanager_secret.tipstaff_db_secrets.id
  secret_string = jsonencode({ "TIPSTAFF_DB_PASSWORD" : "${random_password.password.result}" })
}

data "aws_secretsmanager_secret" "get_tipstaff_db_secrets" {
  depends_on = [aws_secretsmanager_secret_version.rds_credentials]
  arn        = aws_secretsmanager_secret_version.rds_credentials.arn
}

data "aws_secretsmanager_secret_version" "get_rds_credentials" {
  depends_on = [aws_secretsmanager_secret_version.rds_credentials]
  secret_id  = data.aws_secretsmanager_secret.get_tipstaff_db_secrets.id
}

// Secrets for the tactical products database
resource "aws_secretsmanager_secret" "tactical_products_db_secrets" {
  name                    = "tipstaff-tactical-products-db-secrets"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "tactical_products_rds_credentials" {
  secret_id     = aws_secretsmanager_secret.tactical_products_db_secrets.id
  secret_string = jsonencode({ "" : "", "" : "" })
}

data "aws_secretsmanager_secret" "get_tactical_products_db_secrets" {
  depends_on = [aws_secretsmanager_secret_version.tactical_products_rds_credentials]
  arn        = aws_secretsmanager_secret_version.tactical_products_rds_credentials.arn
}

data "aws_secretsmanager_secret_version" "get_tactical_products_rds_credentials" {
  depends_on = [aws_secretsmanager_secret_version.tactical_products_rds_credentials]
  secret_id  = data.aws_secretsmanager_secret.get_tactical_products_db_secrets.id
}

