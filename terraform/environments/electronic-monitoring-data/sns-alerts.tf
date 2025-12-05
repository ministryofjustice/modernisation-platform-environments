resource "aws_sns_topic_policy" "emds_alerts" {
  arn    = aws_sns_topic.emds_alerts.arn
  policy = data.aws_iam_policy_document.emds_alerts_topic_policy.json
}