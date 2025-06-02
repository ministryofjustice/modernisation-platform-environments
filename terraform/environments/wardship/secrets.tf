#### This file can be used to store secrets specific to the member account ####
resource "random_password" "password" {
  length  = 16
  lower   = true
  upper   = true
  numeric = true
  special = false
}

// Secrets for the wardship database on the modernisation platform
resource "aws_secretsmanager_secret" "rds_db_credentials" {
  #checkov:skip=CKV2_AWS_57:Automatic rotation is not required for this secret
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"
  name                    = "rds-password"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id     = aws_secretsmanager_secret.rds_db_credentials.id
  secret_string = jsonencode({ "WARDSHIP_DB_PASSWORD" : random_password.password.result })
}

data "aws_secretsmanager_secret" "get_wardship_db_secrets" {
  depends_on = [aws_secretsmanager_secret_version.rds_credentials]
  arn        = aws_secretsmanager_secret_version.rds_credentials.arn
}

data "aws_secretsmanager_secret_version" "get_rds_credentials" {
  depends_on = [aws_secretsmanager_secret_version.rds_credentials]
  secret_id  = data.aws_secretsmanager_secret.get_wardship_db_secrets.id
}