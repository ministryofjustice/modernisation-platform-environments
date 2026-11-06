# Account alerts topic, managed by the alerting module in the ccms-feasibility root stack
data "aws_sns_topic" "alerts" {
  name = "${local.application_name}-alerts"
}

# Slack webhooks, managed by the alerting module in the ccms-feasibility root stack. The SOA containers post to
# the same channel as CloudWatch alarms (slack_channel_webhook).
data "aws_secretsmanager_secret" "slack_webhooks" {
  name = "${local.application_name}-slack-webhooks"
}
