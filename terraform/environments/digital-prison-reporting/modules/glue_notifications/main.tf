locals {
  tags = merge(
    var.tags,
    {
      Dept = "Digital-Prison-Reporting",
      Jira = "DPR-569"
    }
  )
}

resource "aws_sns_topic_policy" "glue-jobs-notification-policy" {
  arn = aws_sns_topic.glue-jobs-notification-topic.arn

  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  policy_id = "__dpr_glue_jobs_notifications_policy_ID"

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
      aws_sns_topic.glue-jobs-notification-topic.arn,
    ]

    sid = "__dpr_glue_jobs_notifications_statement_ID"
  }
}

resource "aws_sns_topic" "glue-jobs-notification-topic" {
  name = var.sns_topic_name

  tags = merge(
    local.tags,
    {
      Resource_Type = "SNS Topic"
    }
  )
}

resource "aws_cloudwatch_event_rule" "glue-jobs-status-change-rule" {
  name = var.rule_name

  event_pattern = <<PATTERN
{
  "source": ["aws.glue"],
  "detail-type": ["Glue Job State Change"],
  "detail": {
    "state": ["STOPPED", "FAILED", "TIMEOUT"]
  }
}
PATTERN

  tags = merge(
    local.tags,
    {
      Resource_Type = "EventBridge Rule"
    }
  )
}

resource "aws_cloudwatch_event_target" "glue-jobs-notification-target" {
  rule      = aws_cloudwatch_event_rule.glue-jobs-status-change-rule.name
  target_id = var.target_name
  arn       = aws_sns_topic.glue-jobs-notification-topic.arn
}

resource "aws_sns_topic_subscription" "glue-jobs-slack-alerts" {
  count     = var.enable_slack_alerts ? 1 : 0
  topic_arn = aws_sns_topic.glue-jobs-notification-topic.arn
  protocol  = "email"
  endpoint  = var.slack_email_url
}

resource "aws_sns_topic_subscription" "glue-jobs-pagerduty-alerts" {
  count     = var.enable_pagerduty_alerts ? 1 : 0
  topic_arn = aws_sns_topic.glue-jobs-notification-topic.arn
  protocol  = "https"
  endpoint  = var.pagerduty_alerts_url
}