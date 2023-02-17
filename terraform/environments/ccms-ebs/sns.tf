resource "aws_secretsmanager_secret" "support_email_account" {
  name        = "support_email_account"
  description = "email address of the support account for cw alerts"
}
resource "aws_secretsmanager_secret_version" "support_email_account" {
  secret_id = aws_secretsmanager_secret.support_email_account.id
  secret_string = local.support != "" ? local.support  : "default@example.com"
}

resource "aws_sns_topic" "cw_alerts" {
  name = "ccms-ebs-ec2-alerts"
}

resource "aws_sns_topic_policy" "sns_policy" {
  arn    = aws_sns_topic.cw_alerts.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}
/*
resource "aws_sns_topic_subscription" "user_subscription" {
  count     = local.is-production ? 0 : 1
  topic_arn = aws_sns_topic.cw_alerts.arn
  protocol  = "email"
  #endpoint  = data.aws_secretsmanager_secret_version.email.secret_string
  #endpoint = local.support != "" ? local.support : "martytaggart@gmail.com"
  endpoint = aws_secretsmanager_secret_version.support_email_account.secret_string
  depends_on = [
    aws_secretsmanager_secret_version.support_email_account
  ]
}
*/