resource "aws_sns_topic_subscription" "slack-alerts" {
  topic_arn = var.sns_topic_arn
  protocol  = "email"
  endpoint  = var.slack_email_url
}