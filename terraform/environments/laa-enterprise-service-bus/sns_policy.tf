###########################################
### Policy for Provider SNS Topic
###########################################
resource "aws_sns_topic_policy" "priority_p1_policy" {
  arn = aws_sns_topic.priority_p1.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAdminFullAccess"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.admin_role.arn
        }
        Action = [
          "sns:Publish",
          "sns:Subscribe",
          "sns:SetTopicAttributes",
          "sns:RemovePermission",
          "sns:DeleteTopic",
          "sns:GetTopicAttributes",
          "sns:AddPermission"
        ]
        Resource = aws_sns_topic.priority_p1.arn
      },
      {
        Sid    = "AllowPublisherPublishOnly"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.publisher_role.arn
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.priority_p1.arn
      },
      {
        Sid    = "AllowSubscriberSubscribeOnly"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.subscriber_role.arn
        }
        Action   = "sns:Subscribe"
        Resource = aws_sns_topic.priority_p1.arn
      }
    ]
  })
}


###########################################
### Policy for Provider Banks SNS Topic
###########################################
resource "aws_sns_topic_policy" "provider_banks_policy" {
  arn = aws_sns_topic.provider_banks.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAdminFullAccess"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.admin_role.arn
        }
        Action = [
          "sns:Publish",
          "sns:Subscribe",
          "sns:SetTopicAttributes",
          "sns:RemovePermission",
          "sns:DeleteTopic",
          "sns:GetTopicAttributes",
          "sns:AddPermission"
        ]
        Resource = aws_sns_topic.provider_banks.arn
      },
      {
        Sid    = "AllowPublisherPublishOnly"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.publisher_role.arn
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.provider_banks.arn
      },
      {
        Sid    = "AllowSubscriberSubscribeOnly"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.subscriber_role.arn
        }
        Action   = "sns:Subscribe"
        Resource = aws_sns_topic.provider_banks.arn
      }
    ]
  })
}