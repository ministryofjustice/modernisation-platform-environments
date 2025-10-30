#--Alerting Chatbot
module "guardduty_chatbot" {
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

# SNS Topic for Slack Alerts

resource "aws_sns_topic" "cloudwatch_alerts" {
  name            = "cloudwatch-slack-alerts"
  delivery_policy = <<EOF
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
}

resource "aws_sns_topic_policy" "alert_default" {
  arn    = aws_sns_topic.cloudwatch_alerts.arn
  policy = data.aws_iam_policy_document.cloudwatch_alerting_sns.json
}

resource "aws_sns_topic_subscription" "cloudwatch_alerts" {
  topic_arn = aws_sns_topic.cloudwatch_alerts.arn
  protocol  = "https"
  endpoint  = "https://global.sns-api.chatbot.amazonaws.com"
}

resource "aws_sns_topic" "guardduty_alerts" {
  name            = "${local.application_name}-guardduty-alerts"
  delivery_policy = <<EOF
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

# resource "aws_cloudwatch_event_target" "cloudwatch_to_sns" {
#   rule = aws_cloudwatch_event_rule.guardduty.name
#   arn  = aws_sns_topic.guardduty_alerts.arn
# }