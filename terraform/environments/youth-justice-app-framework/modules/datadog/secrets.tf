resource "aws_secretsmanager_secret" "datadog_api" {
  # checkov:skip=CKV2_AWS_57: "Rotation no applicable to as the Datadog Key is maintainan outside AWS."

  name        = var.datadog_api_kpi_secret_name
  description = "Datadog API Key"
  kms_key_id  = var.kms_key_arn
}

resource "aws_secretsmanager_secret_version" "datadog_api" {
  secret_id     = aws_secretsmanager_secret.datadog_api.id
  secret_string = "changeme"
}

