#### This file can be used to store secrets specific to the sftp client account ####
# SFTP BC Application Secrets
resource "aws_secretsmanager_secret" "sftp_bc_secrets" {
  name        = "${local.application_name}-sftp-bc-secrets"
  description = "SFTP bc Ingress Application Secrets"
  kms_key_id  = aws_kms_key.s3_sftp_bc_kms_key.arn
}

resource "aws_secretsmanager_secret_version" "sftp_bc_secrets" {
  secret_id = aws_secretsmanager_secret.sftp_bc_secrets.id
  secret_string = jsonencode({
    ebs_db_username             = "",
    ebs_db_password             = "",
    ebs_db_endpoint             = "",
    file_transfer_slack_webhook = ""
  })

  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
}

data "aws_secretsmanager_secret_version" "sftp_bc_secrets" {
  secret_id = aws_secretsmanager_secret.sftp_bc_secrets.id
}

# SFTP BC Lambda Secrets
resource "aws_secretsmanager_secret" "sftp_bc_lambda_secrets" {
  name        = "${local.application_name}-sftp-bc-lambda-secrets"
  description = "SFTP bc Lambda Secrets"
  kms_key_id  = aws_kms_key.s3_sftp_bc_kms_key.arn
}

resource "aws_secretsmanager_secret_version" "sftp_bc_lambda_secrets" {
  secret_id = aws_secretsmanager_secret.sftp_bc_lambda_secrets.id
  secret_string = jsonencode({
    validate_file = ""
  })

  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
}

data "aws_secretsmanager_secret_version" "sftp_bc_lambda_secrets" {
  secret_id = aws_secretsmanager_secret.sftp_bc_lambda_secrets.id
}