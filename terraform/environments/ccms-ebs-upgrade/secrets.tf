#### This file can be used to store secrets specific to the member account ####

# Slack Channel Webhook Secret for Cloudwatch, GuardDuty & S3 Alerts via Lambda
resource "aws_secretsmanager_secret" "ebs_cw_alerts_secrets" {
  name        = "${local.application_name}-cw-alerts-secrets"
  description = "CCMS EBS Upgrade CloudWatch, GuardDuty & S3 Alerts Secret"
}

resource "aws_secretsmanager_secret_version" "ebs_cw_alerts_secrets" {
  secret_id = aws_secretsmanager_secret.ebs_cw_alerts_secrets.id

  secret_string = jsonencode({
    "slack_channel_webhook"           = "",
    "slack_channel_webhook_guardduty" = "",
    "slack_channel_webhook_s3"        = ""
  })

  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
}
