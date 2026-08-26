resource "aws_sns_topic" "ses_notifications" {
  name              = "ses-bounce-complaint"
  kms_master_key_id = var.key_id
}


resource "aws_sns_topic_policy" "allow_ses_publish" {
  arn = aws_sns_topic.ses_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowSESPublish",
        Effect = "Allow",
        Principal = {
          Service = "ses.amazonaws.com"
        },
        Action   = "SNS:Publish",
        Resource = aws_sns_topic.ses_notifications.arn,
        Condition = {
          StringEquals = {
            "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
          },
          StringLike = {
            "AWS:SourceArn" = "arn:aws:ses:${var.region}:${data.aws_caller_identity.current.account_id}:identity/*"
          }
        }
      }
    ]
  })
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.ses_notifications.arn
  protocol  = "email"
  endpoint  = "yjafsesndr@necsws.com"
}


data "aws_caller_identity" "current" {}


# Bounce Notifications
resource "aws_ses_identity_notification_topic" "bounce_topic" {
  for_each                 = var.ses_domain_identities
  identity                 = aws_ses_domain_identity.main[each.key].domain
  notification_type        = "Bounce"
  topic_arn                = aws_sns_topic.ses_notifications.arn
  include_original_headers = true
  depends_on               = [aws_sns_topic_policy.allow_ses_publish]
}

# Complaint Notifications
resource "aws_ses_identity_notification_topic" "complaint_topic" {
  for_each                 = var.ses_domain_identities
  identity                 = aws_ses_domain_identity.main[each.key].domain
  notification_type        = "Complaint"
  topic_arn                = aws_sns_topic.ses_notifications.arn
  include_original_headers = true
  depends_on               = [aws_sns_topic_policy.allow_ses_publish]
}