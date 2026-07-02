# ---------------------------------------------------------------------------------------------------------------------
# KMS
# ---------------------------------------------------------------------------------------------------------------------
data "aws_iam_policy_document" "inspector_s3_kms" {
  #checkov:skip=CKV_AWS_109:KMS key policies require kms:* on * for the root account - this is an AWS requirement
  #checkov:skip=CKV_AWS_111:KMS key policies require kms:* on * for the root account - this is an AWS requirement
  #checkov:skip=CKV_AWS_356:KMS key policies require * as resource - this is an AWS requirement
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
    sid    = "AllowInspector"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["inspector2.amazonaws.com"]
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

resource "aws_kms_key" "inspector_s3" {
  count                   = contains(local.deploy_to, local.environment) ? 1 : 0
  description             = "KMS key for Inspector findings reports S3 bucket"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.inspector_s3_kms.json
  tags                    = local.extended_tags
}

resource "aws_kms_alias" "inspector_s3" {
  count         = contains(local.deploy_to, local.environment) ? 1 : 0
  name          = "alias/${local.name}-inspector-s3"
  target_key_id = aws_kms_key.inspector_s3[0].key_id
}
