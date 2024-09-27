resource "aws_cloudwatch_log_group" "lambda_cloudwatch_group" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 400
  kms_key_id        = aws_kms_key.lambda_env_key.arn
}

data "aws_caller_identity" "current_acct_id" {}

data "aws_region" "current" {}

data "aws_iam_policy_document" "this_kms_key" {
  statement {
    sid = "EnableIAMUserPermissions"

    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current_acct_id.account_id}:root"]
    }

    effect = "Allow"
  }

  statement {
    sid = "EnableLogServicePermissions"

    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*",
    ]

    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
    }

    effect = "Allow"
  }
}

resource "aws_kms_key" "lambda_env_key" {
  description         = "KMS key for encrypting Lambda environment variables for ${var.function_name}"
  enable_key_rotation = true

  policy = data.aws_iam_policy_document.this_kms_key.json
}