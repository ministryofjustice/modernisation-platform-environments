locals {
  resource_name_prefix = var.name_suffix == "" ? var.application_name : "${var.application_name}-${var.name_suffix}"
}

resource "aws_sns_topic" "clean_bucket_events" {
  name = "${local.resource_name_prefix}-clean-bucket-events"
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
      values   = [var.download_bucket_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.account_id]
    }
  }
}

resource "aws_sns_topic_policy" "clean_bucket_events" {
  arn    = aws_sns_topic.clean_bucket_events.arn
  policy = data.aws_iam_policy_document.clean_bucket_events.json
}

resource "aws_s3_bucket_notification" "clean_bucket_events" {
  bucket = var.download_bucket_name

  topic {
    topic_arn = aws_sns_topic.clean_bucket_events.arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_sns_topic_policy.clean_bucket_events]
}

module "sqs_clean_file_notifications" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "5.2.1"

  name            = "${local.resource_name_prefix}-clean-file-notifications"
  use_name_prefix = false

  create_queue_policy = true
  queue_policy_statements = {
    sns = {
      sid     = "AllowCleanBucketEventsTopicSendMessage"
      actions = ["sqs:SendMessage"]

      principals = [
        {
          type        = "Service"
          identifiers = ["sns.amazonaws.com"]
        }
      ]

      condition = [
        {
          test     = "ArnEquals"
          variable = "aws:SourceArn"
          values   = [aws_sns_topic.clean_bucket_events.arn]
        }
      ]
    }
  }

  create_dlq = true
  dlq_name   = "${local.resource_name_prefix}-clean-file-notifications-dlq"

  message_retention_seconds     = 1209600
  visibility_timeout_seconds    = 180
  receive_wait_time_seconds     = 20
  dlq_message_retention_seconds = 1209600

  redrive_policy = {
    maxReceiveCount = 5
  }

  tags = var.tags
}

resource "aws_sns_topic_subscription" "clean_bucket_events_to_sqs" {
  topic_arn            = aws_sns_topic.clean_bucket_events.arn
  protocol             = "sqs"
  endpoint             = module.sqs_clean_file_notifications.queue_arn
  raw_message_delivery = true
}

resource "aws_sns_topic" "clean_file_download_notifications" {
  name = "${local.resource_name_prefix}-clean-file-download-notifications"
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

module "lambda_clean_file_presigned_url_notifier" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.8.0"

  function_name                = "${local.resource_name_prefix}-clean-file-presigned-url-notifier"
  description                  = "Generates a presigned download URL for clean files and publishes it to SNS"
  handler                      = "lambda_function.lambda_handler"
  runtime                      = "python3.12"
  source_path                  = var.lambda_source_path
  trigger_on_package_timestamp = false

  event_source_mapping = {
    sqs = {
      event_source_arn = module.sqs_clean_file_notifications.queue_arn
      batch_size       = 1
    }
  }

  environment_variables = {
    DOWNLOAD_BUCKET_NAME            = var.download_bucket_name
    DOWNLOAD_URL_EXPIRY_SECONDS     = tostring(var.presigned_url_expiry_seconds)
    IDEMPOTENCY_TABLE               = var.idempotency_table_id
    MAX_DOWNLOAD_URL_EXPIRY_SECONDS = tostring(var.max_presigned_url_expiry_seconds)
    SLACK_SNS_TOPIC_ARN             = aws_sns_topic.clean_file_download_notifications.arn
  }

  attach_policy_statements = true
  policy_statements = {
    clean_bucket_read = {
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetObjectTagging",
        "s3:GetObjectVersionTagging",
      ]
      resources = [
        "${var.download_bucket_arn}/*",
      ]
    }
    clean_bucket_kms_access = {
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:GenerateDataKey*",
      ]
      resources = [
        var.download_bucket_kms_key_arn,
      ]
    }
    idempotency_table_access = {
      effect = "Allow"
      actions = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
      ]
      resources = [
        var.idempotency_table_arn,
      ]
    }
    notification_topic_publish = {
      effect = "Allow"
      actions = [
        "sns:Publish",
      ]
      resources = [
        aws_sns_topic.clean_file_download_notifications.arn,
      ]
    }
  }

  attach_policies    = true
  number_of_policies = 1
  policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole",
  ]

  cloudwatch_logs_retention_in_days = 30

  tags = var.tags
}

module "chatbot_clean_file_download_notifications" {
  count = var.slack_channel_id != null && var.slack_team_id != null ? 1 : 0

  source = "github.com/ministryofjustice/modernisation-platform-terraform-aws-chatbot?ref=0ec33c7bfde5649af3c23d0834ea85c849edf3ac" # v3.0.0

  slack_channel_id = var.slack_channel_id
  slack_team_id    = var.slack_team_id
  sns_topic_arns   = [aws_sns_topic.clean_file_download_notifications.arn]
  tags             = var.tags
  application_name = local.resource_name_prefix
}
