resource "aws_sns_topic" "emds_alerts" {
  name = "emds-alerts"
}

data "aws_iam_policy_document" "emds_alerts_topic_policy" {
  version = "2012-10-17"

  statement {
    sid    = "AllowCloudWatchToPublish"
    effect = "Allow"

    actions = [
      "sns:Publish",
    ]

    resources = [
      aws_sns_topic.emds_alerts.arn
    ]

    principals {
      type = "Service"
      identifiers = [
        "cloudwatch.amazonaws.com"
      ]
    }
  }
}
