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
  kms_master_key_id = aws_kms_key.cloudwatch_sns_alerts_key.id
  tags = merge(local.tags, 
    { Name = "cloudwatch-slack-alerts" }
  )
}

data "aws_iam_policy_document" "cloudwatch_alerting_sns" {
  version = "2012-10-17"
  statement {
    sid    = "EventsAllowPublishSnsTopic"
    effect = "Allow"
    actions = [
      "sns:Publish",
    ]
    resources = [
      aws_sns_topic.cloudwatch_alerts.arn
    ]
    principals {
      type = "Service"
      identifiers = [
        "cloudwatch.amazonaws.com",
      ]
    }
  }
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

