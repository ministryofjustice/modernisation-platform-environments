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
      identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
    }
    resources = ["*"]

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"]
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