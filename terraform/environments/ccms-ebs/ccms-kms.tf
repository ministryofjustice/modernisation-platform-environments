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

# CC-4660: customer-managed key for S3 bucket SSE-KMS encryption.
# GuardDuty Malware Protection scans ccms_ebs_shared, lambda_payment_load and the
# dbbackup bucket via the shared GuardDutyS3MalwareProtectionRole (data.aws_iam_role.guardduty_s3_scan
# in guardduty-s3.tf), so that role must be able to decrypt objects under this key or scanning breaks.
data "aws_iam_policy_document" "s3_cmk" {
  statement {
    sid    = "AllowRootAccountAdmin"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowS3ServiceUseOfKey"
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
      "kms:DescribeKey",
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
      values   = ["s3.${data.aws_region.current.name}.amazonaws.com"]
    }
  }

  statement {
    sid    = "AllowGuardDutyMalwareScanRole"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.guardduty_s3_scan.arn]
    }
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey*",
    ]
    resources = ["*"]
  }
}

resource "aws_kms_key" "s3_cmk" {
  description         = "CMK for SSE-KMS encryption of ${local.application_name} S3 buckets in ${local.environment}"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.s3_cmk.json

  tags = merge(local.tags,
    { Name = "${local.application_name}-${local.environment}-s3-cmk" }
  )
}

resource "aws_kms_alias" "s3_cmk_alias" {
  name          = "alias/${local.application_name}-${local.environment}-s3-cmk"
  target_key_id = aws_kms_key.s3_cmk.key_id
}
