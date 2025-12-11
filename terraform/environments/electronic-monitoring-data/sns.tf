resource "aws_sns_topic" "emds_alerts" {
  name              = "emds-alerts"
  kms_master_key_id = "alias/aws/sns"
}

data "aws_iam_policy_document" "emds_alerts_topic_policy" {
  version = "2012-10-17"

  # Allow CloudWatch alarms to publish
  statement {
    sid    = "AllowCloudWatchToPublish"
    effect = "Allow"

    actions = [
      "sns:Publish",
    ]

    resources = [aws_sns_topic.emds_alerts.arn]

    principals {
      type = "Service"
      identifiers = [
        "cloudwatch.amazonaws.com"
      ]
    }
  }

  # Allow AWS Chatbot HTTPS endpoint ingestion
  statement {
    sid    = "AllowChatbotToConsume"
    effect = "Allow"

    actions = [
      "sns:Subscribe",
      "sns:Receive",
      "sns:Publish"
    ]

    resources = [aws_sns_topic.emds_alerts.arn]

    principals {
      type = "Service"
      identifiers = [
        "sns.amazonaws.com",
        "events.amazonaws.com",
        "chatbot.amazonaws.com"
      ]
    }
  }
}

resource "aws_sns_topic_policy" "emds_alerts" {
  arn    = aws_sns_topic.emds_alerts.arn
  policy = data.aws_iam_policy_document.emds_alerts_topic_policy.json
}

resource "aws_sqs_queue" "emds_alerts_dlq" {
  name                       = "emds-alerts-dlq"
  sqs_managed_sse_enabled    = true
  visibility_timeout_seconds = 60
  message_retention_seconds  = 1209600
}