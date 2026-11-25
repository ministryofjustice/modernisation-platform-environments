#####################################################################################
### Slack Webhook Secret for Security Alerts ###
#####################################################################################

resource "aws_secretsmanager_secret" "slack_security_alerts_webhook" {
  count = contains(["preproduction", "development"], local.environment) ? 1 : 0
  name  = "oas-slack-security-alerts-webhook-${local.environment}"

  tags = merge(
    local.tags,
    {
      Name = "oas-${local.environment}-slack-security-alerts-webhook"
    }
  )
}

# Note: The secret value must be manually populated via AWS Console or CLI
# aws secretsmanager put-secret-value \
#   --secret-id oas-slack-security-alerts-webhook-${environment} \
#   --secret-string '{"webhook_url":"https://hooks.slack.com/services/YOUR/WEBHOOK/URL"}'
