# Allow ARNS to populate database credentials directly into a secret provisioned here
# 1. Set arns_integration object in relevant locals with
#   database_hostname               = string # set to hostname of postgres DB
# 2. Apply terraform + configure the cross-account-config secret with
#      account-id   = ARNS cloud platform AWS account ID
#      iam-role-arn = The ARN of the role populating the secret
# 3. Update arns_integration object in relevant locals and add
#   cross_account_secret_configured = true
# 4. Re-apply terraform

locals {
  arns_integration_default = {
    cross_account_secret_configured = false
    database_hostname               = null
  }
  arns_integration          = merge(local.arns_integration_default, lookup(local.locals_environment_specific, "arns_integration", {}))
  arns_cross_account_config = local.arns_integration.cross_account_secret_configured ? jsondecode(data.aws_secretsmanager_secret_version.arns_integration_cross_account_config[0].secret_string) : null
}

data "aws_iam_policy_document" "arns_integration_kms_policy" {
  #checkov:skip=CKV_AWS_356:skip "Ensure no IAM policies documents allow *" - policy is attached directly to resource
  #checkov:skip=CKV_AWS_109:skip "Ensure IAM policies does not allow permissions management" - constraint is added for cross-account access
  #checkov:skip=CKV_AWS_111:skip "Ensure IAM policies does not allow write access without constraints" - ditto

  statement {
    sid       = "AllowLocalAccess"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"] #
    }
  }

  dynamic "statement" {
    for_each = local.arns_cross_account_config != null ? [local.arns_cross_account_config["account-id"]] : []

    content {
      sid    = "AllowCrossAccountAccess"
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:GenerateDataKey*",
        "kms:ReEncrypt*",
      ]
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${statement.value}:root"]
      }

      condition {
        test     = "StringEquals"
        variable = "kms:ViaService"
        values   = ["secretsmanager.eu-west-2.amazonaws.com"]
      }
    }
  }
}

data "aws_iam_policy_document" "arns_integration_secret_policy" {
  #checkov:skip=CKV_AWS_356:skip "Ensure no IAM policies documents allow *" - policy is attached directly to resource
  #checkov:skip=CKV_AWS_108:skip "Ensure IAM policies does not allow data exfiltration" - access restricted to specific cross-account role
  #checkov:skip=CKV_AWS_111:skip "Ensure IAM policies does not allow write access without constraints" - ditto
  count = local.arns_cross_account_config != null ? 1 : 0

  statement {
    sid    = "AllowCrossAccountReadWrite"
    effect = "Allow"
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecret"
    ]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = [local.arns_cross_account_config["iam-role-arn"]]
    }
  }
}

resource "aws_kms_key" "arns_integration" {
  count = local.arns_integration.database_hostname != null ? 1 : 0

  description         = "KMS key for cross-account resource sharing with ARNS"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.arns_integration_kms_policy.json

  tags = merge(local.tags, {
    Name = "kms-arns-integration-${local.environment}"
  })
}

resource "aws_kms_alias" "arns_integration" {
  count = local.arns_integration.database_hostname != null ? 1 : 0

  name          = "alias/kms-arns-integration-${local.environment}"
  target_key_id = aws_kms_key.arns_integration[0].key_id
}

resource "aws_secretsmanager_secret" "arns_integration_cross_account_config" {
  #checkov:skip=CKV2_AWS_57: skip "Ensure Secrets Manager secrets should have automatic rotation enabled" as secret used to store static config
  count = local.arns_integration.database_hostname != null ? 1 : 0

  name                    = "/postgres/database/${local.arns_integration.database_hostname}/cross-account-config"
  description             = "Cross Account Ids populated outside of terraform"
  kms_key_id              = module.environment.kms_keys["general"].arn
  recovery_window_in_days = 0

  tags = merge(local.tags, {
    Name = "/postgres/database/${local.arns_integration.database_hostname}/cross-account-config"
  })
}

data "aws_secretsmanager_secret_version" "arns_integration_cross_account_config" {
  count = local.arns_integration.cross_account_secret_configured ? 1 : 0

  secret_id = aws_secretsmanager_secret.arns_integration_cross_account_config[0].id
}

resource "aws_secretsmanager_secret" "arns_integration_cloud_platform_config" {
  #checkov:skip=CKV2_AWS_57: skip "Ensure Secrets Manager secrets should have automatic rotation enabled" as secret managed by ARNS terraform
  count = local.arns_integration.database_hostname != null ? 1 : 0

  name                    = "/postgres/database/${local.arns_integration.database_hostname}/cloud-platform-config"
  description             = "Database configuration and passwords populated by Cloud Platform terraform"
  kms_key_id              = aws_kms_key.arns_integration[0].arn
  policy                  = local.arns_cross_account_config != null ? data.aws_iam_policy_document.arns_integration_secret_policy[0].json : null
  recovery_window_in_days = 0

  tags = merge(local.tags, {
    Name = "/postgres/database/${local.arns_integration.database_hostname}/cloud-platform-config"
  })
}



