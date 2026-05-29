resource "aws_sns_topic" "clean_bucket_events" {
  name = "${local.application_name}-clean-bucket-events"
}

data "aws_iam_policy_document" "clean_bucket_events" {
  statement {
    sid     = "AllowCleanBucketPublish"
    effect  = "Allow"
    actions = ["SNS:Publish"]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    resources = [aws_sns_topic.clean_bucket_events.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [module.s3_bucket["clean"].s3_bucket_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sns_topic_policy" "clean_bucket_events" {
  arn    = aws_sns_topic.clean_bucket_events.arn
  policy = data.aws_iam_policy_document.clean_bucket_events.json
}

resource "aws_s3_bucket_notification" "clean_bucket_events" {
  bucket = module.s3_bucket["clean"].s3_bucket_id

  topic {
    topic_arn = aws_sns_topic.clean_bucket_events.arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_sns_topic_policy.clean_bucket_events]
}

resource "aws_sns_topic_subscription" "clean_bucket_events_to_sqs" {
  topic_arn            = aws_sns_topic.clean_bucket_events.arn
  protocol             = "sqs"
  endpoint             = module.sqs_clean_file_notifications.queue_arn
  raw_message_delivery = true
}

resource "aws_sns_topic" "clean_file_download_notifications" {
  name = "${local.application_name}-clean-file-download-notifications"
}

data "aws_iam_policy_document" "clean_file_download_notifications" {
  statement {
    sid    = "AllowChatbotToConsume"
    effect = "Allow"
    actions = [
      "sns:Subscribe",
      "sns:Receive",
      "sns:Publish",
    ]

    resources = [aws_sns_topic.clean_file_download_notifications.arn]

    principals {
      type = "Service"
      identifiers = [
        "sns.amazonaws.com",
        "events.amazonaws.com",
        "chatbot.amazonaws.com",
      ]
    }
  }
}

resource "aws_sns_topic_policy" "clean_file_download_notifications" {
  arn    = aws_sns_topic.clean_file_download_notifications.arn
  policy = data.aws_iam_policy_document.clean_file_download_notifications.json
}
