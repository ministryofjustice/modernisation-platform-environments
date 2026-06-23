# ---------------------------------------------------------------------------------------------------------------------
# KMS
# ---------------------------------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "ecs_cloudwatch_kms" {
  #checkov:skip=CKV_AWS_109: KMS key policy requires permissions management on the key; access is limited to account root and CloudWatch Logs service conditions.
  #checkov:skip=CKV_AWS_111: KMS key policy uses Resource "*" because key policies apply to the attached key; CloudWatch Logs access is constrained by encryption context.
  #checkov:skip=CKV_AWS_356: KMS key policies commonly require Resource "*"; CloudWatch Logs statement is constrained to matching ECS log group ARNs.
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
      values   = ["arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${local.ecs_prefix}*"]
    }
  }
}

resource "aws_kms_key" "ecs_cloudwatch" {
  count                   = contains(local.deploy_to, local.environment) ? 1 : 0
  description             = "KMS key for ECS CloudWatch log groups"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.ecs_cloudwatch_kms.json
  tags                    = local.extended_tags
}

resource "aws_kms_alias" "ecs_cloudwatch" {
  count         = contains(local.deploy_to, local.environment) ? 1 : 0
  name          = "alias/${local.ecs_prefix}-cloudwatch"
  target_key_id = aws_kms_key.ecs_cloudwatch[0].key_id
}
