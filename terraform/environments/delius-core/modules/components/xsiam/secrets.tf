resource "aws_secretsmanager_secret" "xsiam_api" {
  # checkov:skip=CKV2_AWS_57: "Rotation not applicable to as the xsiam Key is maintainan outside AWS."
  name        = "${local.name}-xsiam-api-key"
  description = "API key for xsiam"
}

resource "aws_secretsmanager_secret_version" "xsiam_api" {
  secret_id     = aws_secretsmanager_secret.xsiam_api.id
  secret_string = "change_me"
  lifecycle {
    ignore_changes = [secret_string]
  }
}