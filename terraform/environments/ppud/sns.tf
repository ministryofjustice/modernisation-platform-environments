
#### Cloud Watch ####
resource "aws_sns_topic" "cw_alerts" {
  name = "ppud-ec2-alerts"
}
resource "aws_sns_topic_policy" "sns_policy" {
  arn    = aws_sns_topic.cw_alerts.arn
  policy = data.aws_iam_policy_document.sns_topic_policy_ec2cw.json
}
resource "aws_sns_topic_subscription" "cw_subscription" {
  topic_arn = aws_sns_topic.cw_alerts.arn
  protocol  = "email"
  endpoint  = aws_secretsmanager_secret_version.support_email_account.secret_string
}
