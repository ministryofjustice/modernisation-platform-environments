#### This file can be used to store secrets specific to the member account ####
resource "random_password" "password" {
  length  = 16
  lower   = true
  upper   = true
  numeric = true
  special = false
}

// Secrets for the pra database on the modernisation platform
resource "aws_secretsmanager_secret" "rds_db_credentials" {
  #checkov:skip=CKV2_AWS_57:Automatic rotation is not required for this secret
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"
  name                    = "rds-password"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id     = aws_secretsmanager_secret.rds_db_credentials.id
  secret_string = jsonencode({ "PRA_DB_PASSWORD" : random_password.password.result })
}

data "aws_secretsmanager_secret" "get_pra_db_secrets" {
  depends_on = [aws_secretsmanager_secret_version.rds_credentials]
  arn        = aws_secretsmanager_secret_version.rds_credentials.arn
}

data "aws_secretsmanager_secret_version" "get_rds_credentials" {
  depends_on = [aws_secretsmanager_secret_version.rds_credentials]
  secret_id  = data.aws_secretsmanager_secret.get_pra_db_secrets.id
}

// retrieve secrets for the tactical products database
data "aws_secretsmanager_secret" "get_tactical_products_db_secrets" {
  arn = "arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.current.account_id}:secret:tactical-products-db-secrets-${local.application_data.accounts[local.environment].tactical_products_db_secrets_arn}"
}

data "aws_secretsmanager_secret_version" "get_tactical_products_rds_credentials" {
  secret_id = data.aws_secretsmanager_secret.get_tactical_products_db_secrets.id
}