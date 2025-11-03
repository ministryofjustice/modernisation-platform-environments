###########################################
### Policy for Provider SNS Topic
###########################################
resource "aws_sns_topic_policy" "patch_priority_p1_policy" {
  count = local.environment == "test" ? 1 : 0
  arn   = aws_sns_topic.patch_priority_p1[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAdminFullAccess"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.patch_admin_role[0].arn
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
        Resource = aws_sns_topic.patch_priority_p1[0].arn
      },
      {
        Sid    = "AllowPublisherPublishOnly"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.patch_publisher_role[0].arn
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.patch_priority_p1[0].arn
      },
      {
        Sid    = "AllowSubscriberSubscribeOnly"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.patch_subscriber_role[0].arn
        }
        Action   = "sns:Subscribe"
        Resource = aws_sns_topic.patch_priority_p1[0].arn
      }
    ]
  })
}


###########################################
### Policy for Provider Banks SNS Topic
###########################################
resource "aws_sns_topic_policy" "patch_provider_banks_policy" {
  count = local.environment == "test" ? 1 : 0
  arn   = aws_sns_topic.patch_provider_banks[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAdminFullAccess"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.patch_admin_role[0].arn
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
        Resource = aws_sns_topic.patch_provider_banks[0].arn
      },
      {
        Sid    = "AllowPublisherPublishOnly"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.patch_publisher_role[0].arn
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.patch_provider_banks[0].arn
      },
      {
        Sid    = "AllowSubscriberSubscribeOnly"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.patch_subscriber_role[0].arn
        }
        Action   = "sns:Subscribe"
        Resource = aws_sns_topic.patch_provider_banks[0].arn
      }
    ]
  })
}