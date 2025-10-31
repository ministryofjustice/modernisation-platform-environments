# SNS Topic for Slack Alerts

resource "aws_sns_topic" "cloudwatch_slack" {
  name = "cloudwatch-slack-alerts"
}