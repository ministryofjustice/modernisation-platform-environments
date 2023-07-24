resource "aws_sns_topic_policy" "notification-policy" {
  arn = aws_sns_topic.dpr-notification-topic.arn

  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  policy_id = "__dpr_notifications_policy_ID"

  statement {
    actions = [
      "SNS:Publish"
    ]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [
      aws_sns_topic.dpr-notification-topic.arn,
    ]

    sid = "__dpr_notifications_statement_ID"
  }
}

resource "aws_sns_topic" "dpr-notification-topic" {
  name = var.sns_topic_name

  tags = merge(
    var.tags,
    {
      Resource_Type = "SNS Topic"
    }
  )
}

resource "aws_sns_topic_subscription" "slack-alerts" {
  count     = var.enable_slack_alerts ? 1 : 0
  topic_arn = aws_sns_topic.dpr-notification-topic.arn
  protocol  = "email"
  endpoint  = var.slack_email_url
}

resource "aws_sns_topic_subscription" "pagerduty-alerts" {
  count     = var.enable_pagerduty_alerts ? 1 : 0
  topic_arn = aws_sns_topic.dpr-notification-topic.arn
  protocol  = "https"
  endpoint  = var.pagerduty_alerts_url
}