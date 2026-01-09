resource "aws_sns_topic" "emds_alerts" {
  name              = "emds-alerts-${local.environment_shorthand}"
  kms_master_key_id = aws_kms_key.emds_alerts.arn
}

resource "aws_kms_key" "emds_alerts" {
  description         = "KMS key for EMDS SNS alerts"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.emds_alerts_kms.json
}

data "aws_iam_policy_document" "emds_alerts_kms" {

  # Root full admin of the key
  statement {
    sid       = "AllowAccountRootFullAccess"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  # Allow SNS to use the key
  statement {
    sid       = "AllowSNSUseOfKey"
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
  }

  # Allow CloudWatch Alarms to use the key
  statement {
    sid       = "AllowCloudWatchUseOfKey"
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "emds_alerts_topic_policy" {
  version = "2012-10-17"

  # Allow CloudWatch alarms to publish
  statement {
    sid    = "AllowCloudWatchToPublish"
    effect = "Allow"

    actions = [
      "sns:Publish",
    ]

    resources = [aws_sns_topic.emds_alerts.arn]

    principals {
      type = "Service"
      identifiers = [
        "cloudwatch.amazonaws.com"
      ]
    }
  }

  # Allow AWS Chatbot HTTPS endpoint ingestion
  statement {
    sid    = "AllowChatbotToConsume"
    effect = "Allow"

    actions = [
      "sns:Subscribe",
      "sns:Receive",
      "sns:Publish"
    ]

    resources = [aws_sns_topic.emds_alerts.arn]

    principals {
      type = "Service"
      identifiers = [
        "sns.amazonaws.com",
        "events.amazonaws.com",
        "chatbot.amazonaws.com"
      ]
    }
  }
}

resource "aws_sns_topic_policy" "emds_alerts" {
  arn    = aws_sns_topic.emds_alerts.arn
  policy = data.aws_iam_policy_document.emds_alerts_topic_policy.json
}

resource "aws_sqs_queue" "emds_alerts_dlq" {
  name                       = "emds-alerts-dlq"
  sqs_managed_sse_enabled    = true
  visibility_timeout_seconds = 60
  message_retention_seconds  = 1209600
}
