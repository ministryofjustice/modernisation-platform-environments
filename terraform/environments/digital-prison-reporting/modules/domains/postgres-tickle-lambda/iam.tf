data "aws_secretsmanager_secret" "heartbeat_endpoint_secret" {
  name = var.heartbeat_endpoint_secret_id
}

data "aws_iam_policy_document" "extra_policy_document" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      data.aws_secretsmanager_secret.heartbeat_endpoint_secret.arn
    ]
  }
}

resource "aws_iam_policy" "additional_policy" {
  name        = "${var.postgres_tickle_lambda_name}-secret-policy"
  description = "Extra Policy for accessing the required secret"
  policy      = data.aws_iam_policy_document.extra_policy_document.json
}