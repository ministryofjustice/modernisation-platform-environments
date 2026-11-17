resource "aws_secretsmanager_secret" "xsiam_endpoint" {
  # checkov:skip=CKV2_AWS_57: "Rotation not applicable to as the xsiam Key is maintainan outside AWS."
  name        = "${local.name}-xsiam-endpoint"
  description = "Endpoint for xsiam"
}

resource "aws_secretsmanager_secret_version" "xsiam_endpoint" {
  secret_id     = aws_secretsmanager_secret.xsiam_endpoint.id
  secret_string = "https://placeholder-url.example.com" # Value manually updated
  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "xsiam_api" {
  # checkov:skip=CKV2_AWS_57: "Rotation not applicable to as the xsiam Key is maintainan outside AWS."
  name        = "${local.name}-xsiam-api-key"
  description = "API key for xsiam"
}

resource "aws_secretsmanager_secret_version" "xsiam_api" {
  secret_id     = aws_secretsmanager_secret.xsiam_api.id
  secret_string = "change_me" # Value manually updated
  lifecycle {
    ignore_changes = [secret_string]
  }
}

data "aws_secretsmanager_secret" "xsiam_endpoint" {
  name       = "xsiam-url-endpoint"
  depends_on = [aws_secretsmanager_secret.xsiam_endpoint]
}

data "aws_secretsmanager_secret_version" "xsiam_endpoint" {
  secret_id = data.aws_secretsmanager_secret.xsiam_endpoint.id
}