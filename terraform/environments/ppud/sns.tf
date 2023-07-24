#### Cloud Watch ####
resource "aws_sns_topic" "cw_alerts" {
  count = local.is-production == true ? 1 : 0
  name  = "ppud-prod-cw-alerts"
}
resource "aws_sns_topic_policy" "sns_policy" {
  count  = local.is-production == true ? 1 : 0
  arn    = aws_sns_topic.cw_alerts[0].arn
  policy = data.aws_iam_policy_document.sns_topic_policy_ec2cw[0].json
}
resource "aws_sns_topic_subscription" "cw_subscription" {
  count     = local.is-production == true ? 1 : 0
  topic_arn = aws_sns_topic.cw_alerts[0].arn
  protocol  = "email"
  endpoint  = aws_secretsmanager_secret_version.support_email_account[0].secret_string
}
