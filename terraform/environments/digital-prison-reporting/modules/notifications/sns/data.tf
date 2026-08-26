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