locals {
  validation_encryption_keys = merge(
    {},
    [
      for deployment_key in keys(local.validation_deployments) : {
        "${deployment_key}/audit" = {
          deployment_key = deployment_key
          purpose        = "audit"
        }
        "${deployment_key}/logs" = {
          deployment_key = deployment_key
          purpose        = "logs"
        }
        "${deployment_key}/failures" = {
          deployment_key = deployment_key
          purpose        = "failures"
        }
      }
    ]...
  )
}

data "aws_iam_policy_document" "validation_encryption" {
  for_each = local.validation_encryption_keys

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
    for_each = each.value.purpose == "logs" ? [1] : []

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
        values = [
          "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.validation_function_prefix}-${each.value.deployment_key}",
        ]
      }
    }
  }
}

resource "aws_kms_key" "schema_validation" {
  for_each = local.validation_encryption_keys

  description = "Schema validation ${each.value.purpose} encryption for ${each.value.deployment_key} (${terraform.workspace})."

  enable_key_rotation     = true
  deletion_window_in_days = 30

  policy = data.aws_iam_policy_document.validation_encryption[each.key].json

  tags = local.tags
}

resource "aws_kms_alias" "schema_validation" {
  for_each = local.validation_encryption_keys

  name = "alias/${local.validation_function_prefix}-${each.value.deployment_key}-${each.value.purpose}"

  target_key_id = aws_kms_key.schema_validation[each.key].key_id
}
