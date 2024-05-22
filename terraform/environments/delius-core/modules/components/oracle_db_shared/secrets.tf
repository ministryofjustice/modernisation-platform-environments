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

resource "aws_secretsmanager_secret_version" "delius_core_dba_passwords" {
  secret_id     = aws_secretsmanager_secret.delius_core_dba_passwords.id
  secret_string = "REPLACE"
  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
}

resource "aws_secretsmanager_secret" "delius_core_application_passwords" {
  name        = local.application_secret_name
  description = "Application Users Credentials"
  kms_key_id  = var.account_config.kms_keys.general_shared
  tags        = var.tags
}

data "aws_iam_policy_document" "delius_core_application_passwords" {

  count = var.account_info.application_name == "delius-core" && local.has_mis_environment ? 1 : 0
  statement {
    sid    = "MisAWSAccountToReadTheSecret"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.mis_account_id}:role/instance-role-delius-mis-${var.env_name}-mis-db-1"]
    }
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.delius_core_application_passwords.arn]
  }
}

resource "aws_secretsmanager_secret_policy" "delius_core_application_passwords" {
  count      = length(data.aws_iam_policy_document.delius_core_application_passwords) > 0 ? 1 : 0
  secret_arn = aws_secretsmanager_secret.delius_core_application_passwords.arn
  policy     = data.aws_iam_policy_document.delius_core_application_passwords[count.index].json
}

resource "aws_secretsmanager_secret_version" "delius_core_application_passwords" {
  secret_id     = aws_secretsmanager_secret.delius_core_application_passwords.id
  secret_string = "REPLACE"
  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
}
