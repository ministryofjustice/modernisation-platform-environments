####################################
# SNS Topics and Topic Subscriptions
####################################

# Production - Cloud Watch

resource "aws_sns_topic" "cw_alerts" {
  # checkov:skip=CKV_AWS_26: "SNS topic encryption is not required as no sensitive data is processed through it"
  count = local.is-production == true ? 1 : 0
  name  = "ppud-prod-cw-alerts"
}

resource "aws_sns_topic_policy" "sns_policy" {
  count  = local.is-production == true ? 1 : 0
  arn    = aws_sns_topic.cw_alerts[0].arn
  policy = data.aws_iam_policy_document.sns_topic_policy_ec2cw[0].json
}
resource "aws_sns_topic_subscription" "cw_subscription" {
  count     = local.is-production == true ? 1 : 0
  topic_arn = aws_sns_topic.cw_alerts[0].arn
  protocol  = "email"
  endpoint  = "PPUDAlerts@colt.net"
  #  endpoint  = aws_secretsmanager_secret_version.support_email_account[0].secret_string
}

# PreProduction - Cloud Watch

resource "aws_sns_topic" "cw_uat_alerts" {
  # checkov:skip=CKV_AWS_26: "SNS topic encryption is not required as no sensitive data is processed through it"
  count = local.is-preproduction == true ? 1 : 0
  name  = "ppud-uat-cw-alerts"
}

resource "aws_sns_topic_subscription" "cw_uat_subscription" {
  count     = local.is-preproduction == true ? 1 : 0
  topic_arn = aws_sns_topic.cw_uat_alerts[0].arn
  protocol  = "email"
  endpoint  = "PPUDAlerts@colt.net"
}

resource "aws_sns_topic_policy" "sns_uat_policy" {
  count = local.is-preproduction == true ? 1 : 0
  arn   = aws_sns_topic.cw_uat_alerts[0].arn

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        "Sid" : "__default_statement_ID",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "*"
        },
        "Action" : [
          "SNS:Publish",
          "SNS:RemovePermission",
          "SNS:SetTopicAttributes",
          "SNS:DeleteTopic",
          "SNS:ListSubscriptionsByTopic",
          "SNS:GetTopicAttributes",
          "SNS:Receive",
          "SNS:AddPermission",
          "SNS:Subscribe"
        ],
        "Resource" : "aws_sns_topic.cw_uat_alerts[0].arn",
        "Condition" : {
          "StringEquals" : {
            "AWS:SourceOwner" : "data.aws_caller_identity.current.account_id"
          }
        }
      }
    ]
  })
}

# Production - S3 Bucket Notification

resource "aws_sns_topic" "s3_bucket_notifications_prod" {
  # checkov:skip=CKV_AWS_26: "SNS topic encryption is not required as no sensitive data is processed through it"
  count = local.is-production == true ? 1 : 0
  name  = "s3_bucket_notifications_prod"
}

resource "aws_sns_topic_policy" "s3_bucket_notifications_prod" {
  count  = local.is-production == true ? 1 : 0
  arn    = aws_sns_topic.s3_bucket_notifications_prod[0].arn
  policy = data.aws_iam_policy_document.sns_topic_policy_s3_notifications_prod[0].json
}

resource "aws_sns_topic_subscription" "s3_bucket_notifications_prod_subscription" {
  count     = local.is-production == true ? 1 : 0
  topic_arn = aws_sns_topic.s3_bucket_notifications_prod[0].arn
  protocol  = "email"
  endpoint  = "PPUDAlerts@colt.net"
}

data "aws_iam_policy_document" "sns_topic_policy_s3_notifications_prod" {
  count     = local.is-production == true ? 1 : 0
  policy_id = "s3_bucket_notifications_prod"
  statement {
    sid = "S3-Publish-SNS"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    effect = "Allow"
    actions = [
      "SNS:Publish"
    ]

    condition {
      test     = "ArnLike"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:s3:::moj-log-files-prod"]
    }

    resources = [
      aws_sns_topic.s3_bucket_notifications_prod[0].arn
    ]
  }
}

# Pre-production - S3 Bucket Notification

resource "aws_sns_topic" "s3_bucket_notifications_uat" {
  # checkov:skip=CKV_AWS_26: "SNS topic encryption is not required as no sensitive data is processed through it"
  count = local.is-preproduction == true ? 1 : 0
  name  = "s3_bucket_notifications_uat"
}

resource "aws_sns_topic_policy" "s3_bucket_notifications_uat" {
  count  = local.is-preproduction == true ? 1 : 0
  arn    = aws_sns_topic.s3_bucket_notifications_uat[0].arn
  policy = data.aws_iam_policy_document.sns_topic_policy_s3_notifications_uat[0].json
}

resource "aws_sns_topic_subscription" "s3_bucket_notifications_uat_subscription" {
  count     = local.is-preproduction == true ? 1 : 0
  topic_arn = aws_sns_topic.s3_bucket_notifications_uat[0].arn
  protocol  = "email"
  endpoint  = "PPUDAlerts@colt.net"
}

data "aws_iam_policy_document" "sns_topic_policy_s3_notifications_uat" {
  count     = local.is-preproduction == true ? 1 : 0
  policy_id = "s3_bucket_notifications_uat"
  statement {
    sid = "S3-Publish-SNS"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    effect = "Allow"
    actions = [
      "SNS:Publish"
    ]

    condition {
      test     = "ArnLike"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:s3:::moj-log-files-uat"]
    }

    resources = [
      aws_sns_topic.s3_bucket_notifications_uat[0].arn
    ]
  }
}

# Development - S3 Bucket Notification

resource "aws_sns_topic" "s3_bucket_notifications_dev" {
  # checkov:skip=CKV_AWS_26: "SNS topic encryption is not required as no sensitive data is processed through it"
  count = local.is-development == true ? 1 : 0
  name  = "s3_bucket_notifications_dev"
}

resource "aws_sns_topic_policy" "s3_bucket_notifications_dev" {
  count  = local.is-development == true ? 1 : 0
  arn    = aws_sns_topic.s3_bucket_notifications_dev[0].arn
  policy = data.aws_iam_policy_document.sns_topic_policy_s3_notifications_dev[0].json
}

resource "aws_sns_topic_subscription" "s3_bucket_notifications_dev_subscription" {
  count     = local.is-development == true ? 1 : 0
  topic_arn = aws_sns_topic.s3_bucket_notifications_dev[0].arn
  protocol  = "email"
  endpoint  = "PPUDAlerts@colt.net"
}

data "aws_iam_policy_document" "sns_topic_policy_s3_notifications_dev" {
  count     = local.is-development == true ? 1 : 0
  policy_id = "s3_bucket_notifications_dev"
  statement {
    sid = "S3-Publish-SNS"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    effect = "Allow"
    actions = [
      "SNS:Publish"
    ]

    condition {
      test     = "ArnLike"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:s3:::moj-log-files-dev"]
    }

    resources = [
      aws_sns_topic.s3_bucket_notifications_dev[0].arn
    ]
  }
}