# KMS key for the BC inbound bucket and the application secrets

data "aws_iam_policy_document" "fin_transfer_kms" {
  statement {
    sid = "AllowRootAccountAdmin"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
}

resource "aws_kms_key" "fin_transfer" {
  description         = "KMS key for the ${local.component_name} BC inbound bucket and secrets in ${local.environment}"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.fin_transfer_kms.json

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}"
  })
}

resource "aws_kms_alias" "fin_transfer" {
  name          = "alias/${local.component_name}-${local.env_label}"
  target_key_id = aws_kms_key.fin_transfer.key_id
}
