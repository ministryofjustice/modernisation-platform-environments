resource "aws_kms_key" "securityhub" {
  description             = "KMS key for Security Hub Lambda environment variables in ${var.project_name}"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_kms_key_policy" "securityhub" {
  key_id = aws_kms_key.securityhub.key_id
  policy = data.aws_iam_policy_document.securityhub_kms_key_policy.json
}

resource "aws_kms_alias" "securityhub" {
  name          = "alias/${var.project_name}-securityhub-lambda-environment"
  target_key_id = aws_kms_key.securityhub.key_id
}
