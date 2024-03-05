data "aws_iam_policy_document" "secrets_manager" {
  statement {
    sid = "SecretPermissions"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      aws_secretsmanager_secret.ad_username.arn,
      aws_secretsmanager_secret.ad_password.arn
    ]
  }
}

resource "aws_iam_policy" "secrets_manager" {
  name        = "${var.env_name}-read-access-to-secrets"
  path        = "/"
  description = "Allow ec2 instance to read secrets"
  policy      = data.aws_iam_policy_document.secrets_manager.json

  tags = var.tags
}
