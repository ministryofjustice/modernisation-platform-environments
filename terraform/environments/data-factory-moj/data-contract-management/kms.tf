data "aws_iam_policy_document" "contract_encryption" {
  for_each = local.contract_encryption_keys

  statement {
    sid    = "EnableAccountIAMPermissions"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root",
      ]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = each.key == "logs" ? [1] : []

    content {
      sid    = "AllowCloudWatchLogsEncryption"
      effect = "Allow"

      principals {
        type = "Service"
        identifiers = [
          "logs.${data.aws_region.current.region}.${data.aws_partition.current.dns_suffix}",
        ]
      }

      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey",
      ]

      resources = ["*"]

      condition {
        test     = "ArnEquals"
        variable = "kms:EncryptionContext:aws:logs:arn"
        values   = [local.registration_log_group_arn]
      }
    }
  }

  dynamic "statement" {
    for_each = each.key == "logs" ? [1] : []

    content {
      sid    = "AllowRegistrationRoleThroughCloudWatchLogs"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = ["*"]
      }

      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey",
      ]

      resources = ["*"]

      condition {
        test     = "ArnEquals"
        variable = "aws:PrincipalArn"
        values   = [local.registration_execution_role_arn]
      }

      condition {
        test     = "StringEquals"
        variable = "kms:ViaService"
        values = [
          "logs.${data.aws_region.current.region}.${data.aws_partition.current.dns_suffix}",
        ]
      }

      condition {
        test     = "ArnEquals"
        variable = "kms:EncryptionContext:aws:logs:arn"
        values   = [local.registration_log_group_arn]
      }
    }
  }
}

resource "aws_kms_key" "contract_management" {
  for_each = local.contract_encryption_keys

  description             = "${each.value} (${terraform.workspace})"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.contract_encryption[each.key].json

  tags = local.tags
}

resource "aws_kms_alias" "contract_management" {
  for_each = local.contract_encryption_keys

  name          = "alias/${local.registration_name}-${each.key}"
  target_key_id = aws_kms_key.contract_management[each.key].key_id
}
