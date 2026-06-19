# ---------------------------------------------------------------------------------------------------------------------
# KMS
# ---------------------------------------------------------------------------------------------------------------------

#checkov:skip=CKV_AWS_111:KMS key policies require kms:* on * for the root account - this is an AWS requirement
#checkov:skip=CKV_AWS_109:KMS key policies require kms:* on * for the root account - this is an AWS requirement
#checkov:skip=CKV_AWS_356:KMS key policies require * as resource - this is an AWS requirement

data "aws_iam_policy_document" "s3_kms" {
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
    sid    = "AllowS3"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }
}

resource "aws_kms_key" "s3" {
  count                   = contains(local.deploy_to, local.environment) ? 1 : 0
  description             = "KMS key for S3 buckets"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.s3_kms.json
  tags                    = local.extended_tags
}

resource "aws_kms_alias" "s3" {
  count         = contains(local.deploy_to, local.environment) ? 1 : 0
  name          = "alias/streaming-poc-maf-s3"
  target_key_id = aws_kms_key.s3[0].key_id
}

data "aws_iam_policy_document" "cloudwatch_kms" {
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
      values   = ["arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/kinesis-analytics/*"]
    }
  }
}

resource "aws_kms_key" "cloudwatch" {
  count                   = contains(local.deploy_to, local.environment) ? 1 : 0
  description             = "KMS key for CloudWatch log groups"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.cloudwatch_kms.json
  tags                    = local.extended_tags
}

resource "aws_kms_alias" "cloudwatch" {
  count         = contains(local.deploy_to, local.environment) ? 1 : 0
  name          = "alias/streaming-poc-maf-cloudwatch"
  target_key_id = aws_kms_key.cloudwatch[0].key_id
}

data "aws_iam_policy_document" "sns_kms" {
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
    sid    = "AllowSNS"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }
}

resource "aws_kms_key" "sns" {
  count                   = contains(local.deploy_to, local.environment) ? 1 : 0
  description             = "KMS key for SNS topics"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.sns_kms.json
  tags                    = local.extended_tags
}

resource "aws_kms_alias" "sns" {
  count         = contains(local.deploy_to, local.environment) ? 1 : 0
  name          = "alias/streaming-poc-maf-sns"
  target_key_id = aws_kms_key.sns[0].key_id
}
