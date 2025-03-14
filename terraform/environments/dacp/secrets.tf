resource "random_password" "password" { # tflint-ignore: terraform_required_providers
  length  = 16
  lower   = true
  upper   = true
  numeric = true
  special = false
}

// Secrets for the dacp database on the modernisation platform
resource "aws_secretsmanager_secret" "rds_db_credentials" {
  #checkov:skip=CKV2_AWS_57:Automatic rotation is not required for this secret
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"
  name                    = "rds-password"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  #checkov:skip=CKV2_AWS_57:Automatic rotation is not required for this secret
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"
  secret_id     = aws_secretsmanager_secret.rds_db_credentials.id
  secret_string = jsonencode({ "DACP_DB_PASSWORD" : random_password.password.result })
}

data "aws_secretsmanager_secret" "get_dacp_db_secrets" {
  #checkov:skip=CKV2_AWS_57:Automatic rotation is not required for this secret
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"
  depends_on = [aws_secretsmanager_secret_version.rds_credentials]
  arn        = aws_secretsmanager_secret_version.rds_credentials.arn
}

data "aws_secretsmanager_secret_version" "get_rds_credentials" {
  #checkov:skip=CKV2_AWS_57:Automatic rotation is not required for this secret
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"
  depends_on = [aws_secretsmanager_secret_version.rds_credentials]
  secret_id  = data.aws_secretsmanager_secret.get_dacp_db_secrets.id
}
