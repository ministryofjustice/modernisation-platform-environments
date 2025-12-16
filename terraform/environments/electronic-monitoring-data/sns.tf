resource "aws_sns_topic" "emds_alerts" {
  name              = "emds-alerts"
  kms_master_key_id = aws_kms_key.emds_alerts.arn
}

resource "aws_kms_key" "emds_alerts" {
  description         = "KMS key for EMDS SNS alerts"
  enable_key_rotation = true

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowAccountRootFullAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "AllowSNSUseOfKey",
      "Effect": "Allow",
      "Principal": {
        "Service": "sns.amazonaws.com"
      },
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AllowCloudWatchUseOfKey",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudwatch.amazonaws.com"
      },
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": "*"
    }
  ]
}
EOF
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
