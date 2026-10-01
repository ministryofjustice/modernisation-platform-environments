locals {
  cloudtrail_arn = var.cloudtrail_name != null ? "arn:aws:cloudtrail:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:trail/${var.cloudtrail_name}" : null
}

data "aws_iam_policy_document" "key" {
  #checkov:skip=CKV_AWS_109: "Key policy resource '*' is scoped to this key only, not account-wide; required root account statement"
  #checkov:skip=CKV_AWS_356: "Key policy resource '*' refers to this key only, per AWS KMS key policy semantics"
  #checkov:skip=CKV_AWS_111: "Key policy resource '*' is scoped to this key only; root statement is the standard AWS default key policy"
  statement {
    sid    = "EnableIAMUserPermissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = var.cloudtrail_name != null ? [1] : []
    content {
      sid    = "AllowCloudTrailEncryptLogs"
      effect = "Allow"

      principals {
        type        = "Service"
        identifiers = ["cloudtrail.amazonaws.com"]
      }

      actions   = ["kms:GenerateDataKey*"]
      resources = ["*"]

      condition {
        test     = "StringEquals"
        variable = "aws:SourceArn"
        values   = [local.cloudtrail_arn]
      }

      condition {
        test     = "StringLike"
        variable = "kms:EncryptionContext:aws:cloudtrail:arn"
        values   = ["arn:aws:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/*"]
      }
    }
  }

  dynamic "statement" {
    for_each = var.cloudtrail_name != null ? [1] : []
    content {
      sid    = "AllowCloudTrailDescribeKey"
      effect = "Allow"

      principals {
        type        = "Service"
        identifiers = ["cloudtrail.amazonaws.com"]
      }

      actions   = ["kms:DescribeKey"]
      resources = ["*"]

      condition {
        test     = "StringEquals"
        variable = "aws:SourceArn"
        values   = [local.cloudtrail_arn]
      }
    }
  }

  dynamic "statement" {
    # Publishing to a KMS-encrypted SNS topic uses the SNS encryption context, not the CloudTrail one.
    for_each = var.cloudtrail_name != null ? [1] : []
    content {
      sid    = "AllowCloudTrailPublishToEncryptedSns"
      effect = "Allow"

      principals {
        type        = "Service"
        identifiers = ["cloudtrail.amazonaws.com"]
      }

      actions = [
        "kms:GenerateDataKey*",
        "kms:Decrypt"
      ]

      resources = ["*"]

      condition {
        test     = "StringLike"
        variable = "kms:EncryptionContext:aws:sns:topicArn"
        values   = ["arn:aws:sns:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:*"]
      }
    }
  }

  dynamic "statement" {
    for_each = var.enable_cloudwatch_logs ? [1] : []
    content {
      sid    = "AllowCloudWatchLogsEncrypt"
      effect = "Allow"

      principals {
        type        = "Service"
        identifiers = ["logs.${data.aws_region.current.region}.amazonaws.com"]
      }

      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ]

      resources = ["*"]

      condition {
        test     = "ArnLike"
        variable = "kms:EncryptionContext:aws:logs:arn"
        values   = ["arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:*"]
      }
    }
  }
}

resource "aws_kms_key" "this" {
  description             = "KMS key for ${var.alias}"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = true
  rotation_period_in_days = var.rotation_period_in_days
  policy                  = data.aws_iam_policy_document.key.json

  tags = var.tags
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.alias}"
  target_key_id = aws_kms_key.this.key_id
}
