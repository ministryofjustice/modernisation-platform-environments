resource "aws_kms_key" "oracle_ec2" {
  enable_key_rotation = true

  tags = merge(local.tags,
    { Name = "oracle_ec2" }
  )
}

resource "aws_kms_alias" "oracle_ec2_alias" {
  name          = "alias/ec2_oracle_key"
  target_key_id = aws_kms_key.oracle_ec2.arn
}

# checkov:skip=CKV_AWS_356: KMS key policies require Resource="*"; constrained via principals/conditions
data "aws_iam_policy_document" "cloudwatch_logs_kms_policy" {
  statement {
    sid     = "AllowRootAccountAdmin"
    effect  = "Allow"
    actions = ["kms:*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    resources = ["*"]
  }

  statement {
    sid     = "AllowCloudWatchLogsUseOfKey"
    effect  = "Allow"
    actions = ["kms:Encrypt*", "kms:Decrypt*", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:Describe*"]
    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.region}.amazonaws.com"]
    }
    resources = ["*"]

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:*"]
    }
  }
}

resource "aws_kms_key" "cloudwatch_logs" {
  description         = "CMK used to encrypt CloudWatch log groups"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.cloudwatch_logs_kms_policy.json

  tags = merge(local.tags,
    { Name = "cloudwatch-logs" }
  )
}

resource "aws_kms_alias" "cloudwatch_logs_alias" {
  name          = "alias/cloudwatch-logs-key"
  target_key_id = aws_kms_key.cloudwatch_logs.arn
}

# DB Backup Bucket S3 KMS
data "aws_iam_policy_document" "s3_dbbackup_kms_policy" {
  statement {
    sid = "AllowRootAccountAdmin"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
  statement {
    sid = "AllowUseForS3UseOfKeyUseOfSecretManagerInThisAccount"
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
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.${data.aws_region.current.region}.amazonaws.com"]
    }
  }
  statement {
    sid    = "AllowAnalyticalPlatformIngestionService"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-ingestion-development"]}:role/transfer",
        "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-ingestion-production"]}:role/transfer"
      ]
    }
    actions = [
      "kms:GenerateDataKey",
      "kms:Encrypt"
    ]
    resources = ["*"]
  }
}

resource "aws_kms_alias" "s3_dbbackup_kms_alias" {
  name          = "alias/s3-dbbackup-alias"
  target_key_id = aws_kms_key.s3_sftp_kms_key.key_id
}

resource "aws_kms_key" "s3_dbbackup_kms_key" {
  description         = "KMS for S3 Bucket used for database backup in ${local.environment} environment"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.s3_dbbackup_kms_policy.json
  tags                = merge(local.tags, { Environment = local.environment })
}
