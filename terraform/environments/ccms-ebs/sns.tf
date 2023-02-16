resource "aws_sns_topic" "cw_alerts" {
    name = "ccms-ebs-ec2-alerts"
}

resource "aws_sns_topic_policy" "sns_policy" {
  arn    = aws_sns_topic.cw_alerts.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

resource "aws_sns_topic_subscription" "user_subscription" {
  count     = local.is-production ? 0 : 1
  topic_arn = aws_sns_topic.cw_alerts.arn
  protocol  = "email"
  endpoint  = data.aws_secretsmanager_secret_version.current.secret_string
}