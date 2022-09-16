### S3 KMS
resource "aws_kms_key" "s3" {
  description         = "Encryption key for s3"
  enable_key_rotation = true
  key_usage           = "ENCRYPT_DECRYPT"
  policy              = data.aws_iam_policy_document.s3-kms.json
  is_enabled          = true


  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-s3-kms"
    }
  )
}

data "aws_iam_policy_document" "s3-kms" {
  statement {
    #checkov:skip=CKV_AWS_111
    #checkov:skip=CKV_AWS_109       
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root", "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/cicd-member-user"]
    }
  }
}

resource "aws_kms_alias" "kms-alias" {
  name          = "alias/s3"
  target_key_id = aws_kms_key.s3.arn
}
