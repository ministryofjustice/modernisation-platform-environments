data "aws_iam_policy_document" "extra_policy_document" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = var.secret_arns
  }
}

resource "aws_iam_policy" "secret_access_policy" {
  name        = "${var.postgres_tickle_lambda_name}-secret-access-policy"
  description = "Extra Policy for accessing the required secrets"
  policy      = data.aws_iam_policy_document.extra_policy_document.json
}