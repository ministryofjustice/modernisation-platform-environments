resource "aws_sns_topic" "ses_notifications" {
  name = "ses-bounce-complaint-topic"
}


resource "aws_sns_topic_policy" "allow_ses_publish" {
  arn = aws_sns_topic.ses_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowSESPublish",
        Effect    = "Allow",
        Principal = {
          Service = "ses.amazonaws.com"
        },
        Action    = "SNS:Publish",
        Resource  = aws_sns_topic.ses_notifications.arn,
        Condition = {
          StringEquals = {
            "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

data "aws_caller_identity" "current" {}