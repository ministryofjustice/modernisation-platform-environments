#--Alerting Chatbot
module "cloudwatch_chatbot" {
  source           = "github.com/ministryofjustice/modernisation-platform-terraform-aws-chatbot?ref=0ec33c7bfde5649af3c23d0834ea85c849edf3ac" # v3.0.0"
  slack_channel_id = jsondecode(data.aws_secretsmanager_secret_version.oia_secrets.secret_string)["cloudwatch_slack_channel_id"]
  sns_topic_arns   = [aws_sns_topic.cloudwatch_alerts.arn]
  tags             = local.tags #--This doesn't seem to pass to anything in the module but is a mandatory var. Consider submitting a PR to the module. AW
  application_name = local.application_name
}
module "guardduty_chatbot" {
  source           = "github.com/ministryofjustice/modernisation-platform-terraform-aws-chatbot?ref=0ec33c7bfde5649af3c23d0834ea85c849edf3ac" # v3.0.0"
  slack_channel_id = jsondecode(data.aws_secretsmanager_secret_version.oia_secrets.secret_string)["guardduty_slack_channel_id"]
  sns_topic_arns   = [aws_sns_topic.guardduty_alerts.arn]
  tags             = local.tags #--This doesn't seem to pass to anything in the module but is a mandatory var. Consider submitting a PR to the module. AW
  application_name = local.application_name
}

#--Altering SNS


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

# resource "aws_cloudwatch_event_target" "cloudwatch_to_sns" {
#   rule = aws_cloudwatch_event_rule.guardduty.name
#   arn  = aws_sns_topic.guardduty_alerts.arn
# }