locals {
  account_id_placeholder = "placeholder"
}

resource "aws_secretsmanager_secret" "allied_account_id" {
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"
  name                    = "account_ids/allied"
  recovery_window_in_days = 0

  tags = merge(
    local.tags
  )
}

resource "aws_secretsmanager_secret_version" "allied_account_id" {
  secret_id     = aws_secretsmanager_secret.allied_account_id.id
  secret_string = jsonencode(local.account_id_placeholder)

  lifecycle {
    ignore_changes = [secret_string, ]
  }

  depends_on = [aws_secretsmanager_secret.allied_account_id]
}

resource "aws_secretsmanager_secret" "home_office_account_id" {
  count = local.is-production || local.is-test ? 1 : 0
  #checkov:skip=CKV2_AWS_57: “Ignore - Ensure Secrets Manager secrets should have automatic rotation enabled"
  #checkov:skip=CKV_AWS_149: "Ensure that Secrets Manager secret is encrypted using KMS CMK"
  name                    = "account_ids/home_office"
  recovery_window_in_days = 0

  tags = merge(
    local.tags
  )
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "aws_secretsmanager_secret_version" "home_office_account_id" {
  count         = local.is-production ? 1 : 0
  secret_id     = aws_secretsmanager_secret.home_office_account_id[0].id
  secret_string = jsonencode(local.account_id_placeholder)

  lifecycle {
    ignore_changes = [secret_string, ]
  }

  depends_on = [aws_secretsmanager_secret.home_office_account_id[0]]
}

module "cross_account_details" {
  count  = local.is-test || local.is-production ? 1 : 0
  source = "terraform-aws-modules/secrets-manager/aws"

  name_prefix             = "cross_account_details"
  description             = "Details for cross account share"
  recovery_window_in_days = 30

  create_policy       = true
  block_public_policy = true
  policy_statements = {
    read = {
      sid = "AllowAccountRead"
      principals = [{
        type        = "AWS"
        identifiers = [aws_iam_role.cross_account_copy[0].arn]
      }]
      actions   = ["secretsmanager:GetSecretValue"]
      resources = ["*"]
    }
  }

  ignore_secret_changes = true
  secret_string = jsonencode({
    fms_general_bucket   = ""
    fms_general_kms_id   = ""
    fms_ho_bucket        = ""
    fms_ho_kms_id        = ""
    fms_specials_bucket  = ""
    fms_specials_kms_id  = ""
    mdss_general_bucket  = ""
    mdss_general_kms_id  = ""
    mdss_specials_bucket = ""
    mdss_specials_kms_id = ""
    mdss_ho_bucket       = ""
    mdss_ho_kms_id       = ""
    account_id           = ""
  })

  tags = local.tags
}
