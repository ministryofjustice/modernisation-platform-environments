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

##Another secret for the apikey but this time it is just plaintext and not a key value pair
resource "aws_secretsmanager_secret" "plain_datadog_api" {
  # checkov:skip=CKV2_AWS_57: "Rotation no applicable to as the Datadog Key is maintainan outside AWS."

  name        = "plain-${var.datadog_api_kpi_secret_name}"
  description = "Datadog API Key but just text"
  kms_key_id  = var.kms_key_arn
}

resource "aws_secretsmanager_secret_version" "plain_datadog_api" {
  secret_id     = aws_secretsmanager_secret.plain_datadog_api.id
  secret_string = "changeme"
}

resource "aws_secretsmanager_secret_policy" "allow_firehose_access" {
  secret_arn = aws_secretsmanager_secret.datadog_api.arn

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid : "AllowFirehoseAccess",
        Effect : "Allow",
        Principal = {
          AWS = aws_iam_role.firehose_to_datadog.arn
        },
        Action   = "secretsmanager:GetSecretValue",
        Resource = aws_secretsmanager_secret.datadog_api.arn
      }
    ]
  })
}
