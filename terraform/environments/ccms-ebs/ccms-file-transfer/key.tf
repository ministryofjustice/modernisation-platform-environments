
data "aws_iam_policy_document" "s3_sftp_bc_kms_policy" {
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
      values   = ["secretsmanager.${data.aws_region.current.name}.amazonaws.com"]
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

resource "aws_kms_alias" "s3_sftp_bc_kms_alias" {
  name          = "alias/s3-sftp-bc-alias"
  target_key_id = aws_kms_key.s3_sftp_bc_kms_key.key_id
}

resource "aws_kms_key" "s3_sftp_bc_kms_key" {
  description         = "KMS for S3 Bucket used by SFTP bc application in ${local.environment} environment"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.s3_sftp_bc_kms_policy.json
  tags                = merge(local.tags, { Environment = local.environment })
}
