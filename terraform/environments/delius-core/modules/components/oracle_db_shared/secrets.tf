resource "aws_secretsmanager_secret" "delius_core_dba_passwords" {
  name        = local.dba_secret_name
  description = "DBA Users Credentials"
  kms_key_id  = var.account_config.kms_keys.general_shared
  tags        = var.tags
}

data "aws_iam_policy_document" "delius_core_dba_passwords" {
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

resource "aws_secretsmanager_secret_policy" "delius_core_dba_passwords" {
  secret_arn = aws_secretsmanager_secret.delius_core_dba_passwords.arn
  policy     = data.aws_iam_policy_document.delius_core_dba_passwords.json
}
