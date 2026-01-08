#### This file can be used to store secrets specific to the member account ####

resource "aws_secretsmanager_secret" "secret_eucs_entra" {
  count       = local.is-development ? 1 : 0
  name        = "eucs-entra-${local.environment}-aws-key"
  description = "Credentials for authenticating to EUCS Entra."

  tags = merge(local.tags,
    { Name = "eucs-entra-${local.environment}-aws-key" }
  )
}

resource "aws_secretsmanager_secret" "secret_ftp_s3" {
  name        = "ftp-s3-${local.environment}-aws-key"
  description = "AWS credentials for mounting of s3 buckets for the FTP Service to access."

  tags = merge(local.tags,
    { Name = "ftp-s3-${local.environment}-aws-key" }
  )
}

resource "aws_secretsmanager_secret" "secret_ses_smtp_credentials" {
  name        = "ses-smtp-credentials"
  description = "SMTP credentials for Postfix to send messages through SES."

  tags = merge(local.tags,
    { Name = "ses-smtp-credentials-${local.environment}" }
  )
}

# Secret for Payment Load

resource "aws_secretsmanager_secret" "secret_lambda_s3" {
  name        = "db-${local.environment}-credentials"
  description = "AWS credentials for lambda to connect to the db."

  tags = merge(local.tags,
    { Name = "db-${local.environment}-credentials" }
  )
}

# Slack Channel ID for guardduty Alerts
resource "aws_secretsmanager_secret" "guardduty_slack_channel_id" {
  name        = "guardduty_slack_channel_id"
  description = "Slack Channel ID for guardduty Alerts"
}

data "aws_secretsmanager_secret_version" "guardduty_slack_channel_id" {
  secret_id = aws_secretsmanager_secret.guardduty_slack_channel_id.id
}

# Slack Channel Webhook Secret for Cloudwatch & GuardDuty Alerts via Lambda
resource "aws_secretsmanager_secret" "ebs_cw_alerts_secrets" {
  name        = "${local.application_name}-cw-alerts-secrets"
  description = "CCMS CloudWatch & GuardDuty Alerts Secret"
}

resource "aws_secretsmanager_secret_version" "ebs_cw_alerts_secrets" {
  secret_id = aws_secretsmanager_secret.ebs_cw_alerts_secrets.id

  secret_string = jsonencode({
    "slack_channel_webhook"           = "",
    "slack_channel_webhook_guardduty" = ""
  })

  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
}
