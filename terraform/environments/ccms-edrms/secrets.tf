#### This file can be used to store secrets specific to the member account ####

resource "aws_secretsmanager_secret" "spring_datasource_password" {
  name        = "ccms/edrms/datasource"
  description = "EDRMS TDS database password for CCMS EDRMS application"
}

data "aws_secretsmanager_secret_version" "spring_datasource_password" {
  secret_id = aws_secretsmanager_secret.spring_datasource_password.id
}

resource "aws_secretsmanager_secret_version" "edrms_secrets" {
  secret_id = aws_secretsmanager_secret.edrms_secrets.id
  secret_string = jsonencode({
    "slack_channel_webhook"           = ""
    "slack_channel_webhook_guardduty" = ""
    "slack_channel_webhook_docs"      = ""
    "slack_channel_webhook_s3"        = ""
  })

  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
}
