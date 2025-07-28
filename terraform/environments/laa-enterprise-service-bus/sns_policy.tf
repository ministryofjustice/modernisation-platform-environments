resource "aws_sns_topic_policy" "priority_p1_policy" {
  arn    = aws_sns_topic.priority_p1.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowAdminFullAccess"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.admin_role.arn
        }
        Action = "sns:*"
        Resource = aws_sns_topic.priority_p1.arn
      },
      {
        Sid = "AllowPublisherPublishOnly"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.provider_pub.arn
        }
        Action = "sns:Publish"
        Resource = aws_sns_topic.priority_p1.arn
      },
      {
        Sid = "AllowSubscriberSubscribeOnly"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.subscriber_role.arn
        }
        Action = "sns:Subscribe"
        Resource = aws_sns_topic.priority_p1.arn
      }
    ]
  })
}