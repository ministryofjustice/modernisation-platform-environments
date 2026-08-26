# Oracle Database DBA Secret

resource "aws_secretsmanager_secret" "database_dba_passwords" {
  #checkov:skip=CKV2_AWS_57
  name        = local.dba_secret_name
  description = "DBA Users Credentials"
  kms_key_id  = var.account_config.kms_keys.general_shared
  tags        = var.tags
}

moved {
  from = aws_secretsmanager_secret.delius_core_dba_passwords
  to   = aws_secretsmanager_secret.database_dba_passwords
}

data "aws_iam_policy_document" "database_dba_passwords" {
  #checkov:skip=CKV_AWS_108 "ignore"
  #checkov:skip=CKV_AWS_356 "ignore"
  statement {
    sid    = "OemAWSAccountToReadTheSecret"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.oem_account_id}:role/EC2OracleEnterpriseManagementSecretsRole"]
    }
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["*"]
  }
}

resource "aws_secretsmanager_secret_policy" "database_dba_passwords" {
  secret_arn = aws_secretsmanager_secret.database_dba_passwords.arn
  policy     = data.aws_iam_policy_document.database_dba_passwords.json
}

# Oracle Database Application Secret
resource "aws_secretsmanager_secret" "database_application_passwords" {
  #checkov:skip=CKV2_AWS_57
  name        = local.application_secret_name
  description = "Application Users Credentials"
  kms_key_id  = var.account_config.kms_keys.general_shared
  tags        = var.tags
}

moved {
  from = aws_secretsmanager_secret.delius_core_application_passwords
  to   = aws_secretsmanager_secret.database_application_passwords
}

# Probation Integration Secrets
resource "aws_secretsmanager_secret" "probation_integration_passwords" {
  #checkov:skip=CKV2_AWS_57
  count       = "${var.account_info.application_name}-${var.env_name}" == "delius-core-preprod" ? 1 : 0
  name        = "${var.account_info.application_name}-${var.env_name}-probation-integration"
  description = "Probation Integration Secrets"
  kms_key_id  = var.account_config.kms_keys.general_shared
  tags        = var.tags
}