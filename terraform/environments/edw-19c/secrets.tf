#### This file can be used to store secrets specific to the member account ####

# Slack notifications: keep the incoming webhook URL out of code and load it at runtime.
# Posts to #laa-alerts-oas-edw (shared with OAS). Populate manually after the first apply:
# aws secretsmanager put-secret-value --no-cli-pager \
#   --secret-id edw-19c/<environment>/security-alerts-slack-webhook \
#   --secret-string '{"webhook_url":"https://hooks.slack.com/services/..."}'
resource "aws_secretsmanager_secret" "security_alerts_slack_webhook" {
  count                   = local.enable_edw_security_alerts ? 1 : 0
  name                    = "${local.application_name}/${local.environment}/security-alerts-slack-webhook"
  description             = "Slack incoming webhook URL for EDW security alerts (#laa-alerts-oas-edw)"
  recovery_window_in_days = 0

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}/${local.environment}/security-alerts-slack-webhook" }
  )
}
