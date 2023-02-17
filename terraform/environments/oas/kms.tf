data "aws_iam_policy_document" "ebs-kms" {
  statement {
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "aws_kms_key" "ebs" {
  description         = "Encryption key for EBS volumes"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.ebs-kms.json

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name} EBS KMS" },
  )
}

resource "aws_kms_alias" "ebs" {
  name          = "alias/oas-ebs-kms"
  target_key_id = aws_kms_key.ebs.key_id
}