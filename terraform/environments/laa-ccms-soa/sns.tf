resource "aws_sns_topic" "s3_topic" {
  name   = "s3-event-notification-topic"
  policy = data.aws_iam_policy_document.s3_topic_policy.json
}