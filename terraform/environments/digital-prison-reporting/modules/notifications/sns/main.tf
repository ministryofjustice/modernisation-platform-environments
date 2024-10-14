resource "aws_sns_topic_policy" "notification-policy" {
  arn = aws_sns_topic.dpr-notification-topic.arn

  policy = data.aws_iam_policy_document.sns_topic_policy.json
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