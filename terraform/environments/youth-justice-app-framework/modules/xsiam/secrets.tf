#### secrets for url and api key

resource "aws_secretsmanager_secret" "xsiam_endpoint" {
  #checkov:skip=CKV2_AWS_57:xsiam endpoint, no rotation needed
  name        = "xsiam-url-endpoint"
  description = "http endpoint for xsiam"
  kms_key_id  = var.kms_key_arn
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "xsiam_endpoint" {
  #checkov:skip=CKV2_AWS_57:xsiam endpoint, no rotation needed
  secret_id     = aws_secretsmanager_secret.xsiam_endpoint.id
  secret_string = "https://placeholder-url.example.com"
  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "xsiam_api" {
  # checkov:skip=CKV2_AWS_57: "Rotation no applicable to as the xsiam Key is maintainan outside AWS."

  name        = "xsiam-api"
  description = "API key for xsiam"
  kms_key_id  = var.kms_key_arn
}

resource "aws_secretsmanager_secret_version" "xsiam_api" {
  secret_id     = aws_secretsmanager_secret.xsiam_api.id
  secret_string = "changeme"
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