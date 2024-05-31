resource "aws_secretsmanager_secret" "this" {
  name        = var.name
  description = var.description
  kms_key_id  = var.kms_key_id
  tags        = var.tags
}

data "aws_iam_policy_document" "this" {
  count = length(var.allowed_account_ids) > 0 ? 1 : 0
  statement {
    sid    = "EnableAnotherAWSAccountToReadTheSecret"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [for account in var.allowed_account_ids : "arn:aws:iam::${account}:root"]
    }

    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.this.arn]
  }
}

resource "aws_secretsmanager_secret_policy" "this" {
  count      = length(var.allowed_account_ids) > 0 ? 1 : 0
  secret_arn = aws_secretsmanager_secret.this.arn
  policy     = data.aws_iam_policy_document.this[0].json
}
