# ---------------------------------------------------------------------------------------------------------------------
# KMS
# ---------------------------------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "ecs_cloudwatch_kms" {
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
  statement {
    sid    = "AllowCloudWatchLogs"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
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
      values   = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${local.ecs_prefix}*"]
    }
  }
}

resource "aws_kms_key" "ecs_cloudwatch" {
  count                   = contains(["development"], local.environment) ? 1 : 0
  description             = "KMS key for ECS CloudWatch log groups"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.ecs_cloudwatch_kms.json
  tags                    = local.extended_tags
}

resource "aws_kms_alias" "ecs_cloudwatch" {
  count         = contains(["development"], local.environment) ? 1 : 0
  name          = "alias/${local.ecs_prefix}-cloudwatch"
  target_key_id = aws_kms_key.ecs_cloudwatch[0].key_id
}
