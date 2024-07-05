# Database Read Access
resource "aws_secretsmanager_secret" "dms_audit_endpoint_source" {
  name        = local.dms_audit_endpoint_source_secret_name
  description = "DMS Database Endpoint for Reading Audited Interaction Replication Data"
  kms_key_id  = var.account_config.kms_keys.general_shared
  tags        = var.tags
}

data "aws_iam_policy_document" "dms_audit_endpoint_source" {
  statement {
    sid    = "DMSRoleToReadTheSecret"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.delius_account_id}:role/DMSSecretsManagerAccessRole"]
    }
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.dms_audit_endpoint_source.arn]
  }
}

resource "aws_secretsmanager_secret_policy" "dms_audit_endpoint_source" {
  secret_arn = aws_secretsmanager_secret.dms_audit_endpoint_source.arn
  policy     = data.aws_iam_policy_document.dms_audit_endpoint_source.json
}


# ASM Read Access
resource "aws_secretsmanager_secret" "dms_asm_endpoint_source" {
  name        = local.dms_asm_endpoint_source_secret_name
  description = "DMS ASM Endpoint"
  kms_key_id  = var.account_config.kms_keys.general_shared
  tags        = var.tags
}

data "aws_iam_policy_document" "dms_asm_endpoint_source" {
  statement {
    sid    = "DMSRoleToReadTheSecret"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.delius_account_id}:role/DMSSecretsManagerAccessRole"]
    }
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.dms_asm_endpoint_source.arn]
  }
}

resource "aws_secretsmanager_secret_policy" "dms_asm_endpoint_source" {
  secret_arn = aws_secretsmanager_secret.dms_asm_endpoint_source.arn
  policy     = data.aws_iam_policy_document.dms_asm_endpoint_source.json
}


# Database Write Access
resource "aws_secretsmanager_secret" "dms_audit_endpoint_target" {
  name        = local.dms_audit_endpoint_target_secret_name
  description = "DMS Database Endpoint for Writing Audited Interaction Replication Data"
  kms_key_id  = var.account_config.kms_keys.general_shared
  tags        = var.tags
}

data "aws_iam_policy_document" "dms_audit_endpoint_target" {
  statement {
    sid    = "DMSRoleToReadTheSecret"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.delius_account_id}:role/DMSSecretsManagerAccessRole"]
    }
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.dms_audit_endpoint_target.arn]
  }
}

resource "aws_secretsmanager_secret_policy" "dms_audit_endpoint_target" {
  secret_arn = aws_secretsmanager_secret.dms_audit_endpoint_target.arn
  policy     = data.aws_iam_policy_document.dms_audit_endpoint_target.json
}

