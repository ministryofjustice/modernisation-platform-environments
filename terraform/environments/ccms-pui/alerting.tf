# #--Alerting Chatbot
# module "guardduty_chatbot" {
#   source           = "github.com/ministryofjustice/modernisation-platform-terraform-aws-chatbot?ref=0ec33c7bfde5649af3c23d0834ea85c849edf3ac" # v3.0.0"
#   slack_channel_id = jsondecode(data.aws_secretsmanager_secret_version.pui_secrets.secret_string)["guardduty_slack_channel_id"]
#   sns_topic_arns   = [aws_sns_topic.guardduty_alerts.arn]
#   tags             = local.tags #--This doesn't seem to pass to anything in the module but is a mandatory var. Consider submitting a PR to the module. AW
#   application_name = local.application_data.accounts[local.environment].app_name
# }

# #--Alerting Chatbot
# module "cloudwatch_chatbot" {
#   source           = "github.com/ministryofjustice/modernisation-platform-terraform-aws-chatbot?ref=0ec33c7bfde5649af3c23d0834ea85c849edf3ac" # v3.0.0"
#   slack_channel_id = jsondecode(data.aws_secretsmanager_secret_version.pui_secrets.secret_string)["cloudwatch_slack_channel_id"]
#   sns_topic_arns   = [aws_sns_topic.cloudwatch_alerts.arn]
#   tags             = local.tags #--This doesn't seem to pass to anything in the module but is a mandatory var. Consider submitting a PR to the module. AW
#   application_name = local.application_name
# }

#--Altering SNS
resource "aws_sns_topic" "guardduty_alerts" {
  name              = "${local.application_data.accounts[local.environment].app_name}-guardduty-alerts"
  delivery_policy   = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultRequestPolicy": {
      "headerContentType": "text/plain; charset=UTF-8"
    }
  }
}
EOF
  kms_master_key_id = aws_kms_key.cloudwatch_sns_alerts_key.id
  tags = merge(local.tags,
    { Name = "${local.application_data.accounts[local.environment].app_name}-guardduty-alerts" }
  )
}

resource "aws_sns_topic_policy" "guarduty_default" {
  arn    = aws_sns_topic.guardduty_alerts.arn
  policy = data.aws_iam_policy_document.guardduty_alerting_sns.json
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

