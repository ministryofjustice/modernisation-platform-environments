resource "aws_sns_topic_policy" "notification-policy" {
  arn = aws_sns_topic.dpr-notification-topic.arn

  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

resource "aws_sns_topic" "dpr-notification-topic" {

  #checkov:skip=CKV_AWS_26: "Ensure all data stored in the SNS topic is Encrypted"

  name = var.sns_topic_name

  tags = var.tags

  lifecycle {
    ignore_changes = [tags]
  }
}