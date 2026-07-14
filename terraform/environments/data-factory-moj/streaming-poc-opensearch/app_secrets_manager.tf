resource "random_string" "master_username" {
  count   = contains(["development"], local.environment) ? 1 : 0
  length  = 16
  special = false
}

resource "random_password" "master_password" {
  count            = contains(["development"], local.environment) ? 1 : 0
  length           = 32
  special          = true
  override_special = "!#$%^&*"
}

data "aws_iam_policy_document" "os_secrets_kms" {
  #checkov:skip=CKV_AWS_111:KMS key policies require kms:* on * for the root account - this is an AWS requirement
  #checkov:skip=CKV_AWS_109:KMS key policies require kms:* on * for the root account - this is an AWS requirement
  #checkov:skip=CKV_AWS_356:KMS key policies require * as resource - this is an AWS requirement
  count = contains(["development"], local.environment) ? 1 : 0
  statement {
    sid    = "EnableRootAccess"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
}

resource "aws_kms_key" "os_secrets_kms" {
  count                   = contains(["development"], local.environment) ? 1 : 0
  description             = "Custom KMS key for Secrets Manager"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.os_secrets_kms[0].json
  tags                    = local.extended_tags
}

resource "aws_kms_alias" "os_secrets_kms" {
  count         = contains(["development"], local.environment) ? 1 : 0
  name          = "alias/streaming-poc-opensearch-secret"
  target_key_id = aws_kms_key.os_secrets_kms[0].key_id
}

resource "aws_secretsmanager_secret" "opensearch_credentials" {
  #checkov:skip=CKV2_AWS_57:Skipping because we do not need rotation.
  count      = contains(["development"], local.environment) ? 1 : 0
  name       = "${local.cluster_name}/master-credentials"
  kms_key_id = aws_kms_key.os_secrets_kms[0].arn
}

resource "aws_secretsmanager_secret_version" "opensearch_credentials" {
  count     = contains(["development"], local.environment) ? 1 : 0
  secret_id = aws_secretsmanager_secret.opensearch_credentials[0].id
  secret_string = jsonencode({
    username = random_string.master_username[0].result
    password = random_password.master_password[0].result
  })
}
