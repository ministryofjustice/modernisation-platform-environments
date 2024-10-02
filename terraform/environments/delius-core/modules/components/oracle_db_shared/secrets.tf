# Oracle Database DBA Secret

resource "aws_secretsmanager_secret" "database_dba_passwords" {
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
  name        = local.application_secret_name
  description = "Application Users Credentials"
  kms_key_id  = var.account_config.kms_keys.general_shared
  tags        = var.tags
}

moved {
  from = aws_secretsmanager_secret.delius_core_application_passwords
  to   = aws_secretsmanager_secret.database_application_passwords
}