#--Alerting Chatbot
module "guardduty_chatbot" {
  source           = "github.com/ministryofjustice/modernisation-platform-terraform-aws-chatbot?ref=73280f80ce8a4557cec3a76ee56eb913452ca9aa" # v2.0.0"
  slack_channel_id = data.aws_secretsmanager_secret_version.guardduty_slack_channel_id.secret_string
  sns_topic_arns   = [aws_sns_topic.guardduty_alerts.arn]
  tags             = local.tags #--This doesn't seem to pass to anything in the module but is a mandatory var. Consider submitting a PR to the module. AW
  application_name = local.application_name
}

resource "aws_sns_topic_policy" "guarduty_default" {
  arn    = aws_sns_topic.guardduty_alerts.arn
  policy = data.aws_iam_policy_document.guardduty_alerting_sns.json
}

resource "aws_sns_topic_subscription" "guardduty_alerts" {
  topic_arn = aws_sns_topic.guardduty_alerts.arn
  protocol  = "https"
  endpoint  = "https://global.sns-api.chatbot.amazonaws.com"
}

resource "aws_cloudwatch_event_rule" "guardduty" {
  name = "${local.application_name}-guardduty-findings"
  event_pattern = jsonencode({
    "source" : ["aws.guardduty"],
    "detail-type" : ["GuardDuty Finding"]
  })
}

resource "aws_cloudwatch_event_target" "guardduty_to_sns" {
  rule = aws_cloudwatch_event_rule.guardduty.name
  arn  = aws_sns_topic.guardduty_alerts.arn
}
