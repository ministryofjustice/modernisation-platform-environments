locals {
  resource_name_prefix = var.name_suffix == "" ? var.application_name : "${var.application_name}-${var.name_suffix}"
}

module "dynamodb_idempotency" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "5.5.0"

  name         = "${local.resource_name_prefix}-presigned-url-idempotency"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attributes = [
    {
      name = "id"
      type = "S"
    }
  ]

  table_class        = "STANDARD"
  ttl_attribute_name = "expiration"
  ttl_enabled        = true
  timeouts = {
    create = "60m"
    delete = "60m"
    update = "60m"
  }

  tags = var.tags
}

module "sns_clean_bucket_events" {
  source  = "terraform-aws-modules/sns/aws"
  version = "7.1.0"

  name = "${local.resource_name_prefix}-clean-bucket-events"

  topic_policy_statements = {
    clean_bucket_publish = {
      actions = ["sns:Publish"]
      principals = [{
        type        = "Service"
        identifiers = ["s3.amazonaws.com"]
      }]
      conditions = [
        {
          test     = "ArnEquals"
          variable = "aws:SourceArn"
          values   = [var.download_bucket_arn]
        },
        {
          test     = "StringEquals"
          variable = "aws:SourceAccount"
          values   = [var.account_id]
        }
      ]
    }
    sqs_subscribe = {
      actions = [
        "sns:Subscribe",
      ]
      principals = [{
        type        = "AWS"
        identifiers = [var.account_id]
      }]
      conditions = [
        {
          test     = "StringEquals"
          variable = "sns:Protocol"
          values   = ["sqs"]
        },
        {
          test     = "StringEquals"
          variable = "sns:Endpoint"
          values   = [module.sqs_clean_file_notifications.queue_arn]
        }
      ]
    }
  }

  subscriptions = {
    sqs = {
      protocol             = "sqs"
      endpoint             = module.sqs_clean_file_notifications.queue_arn
      raw_message_delivery = true
    }
  }

  tags = var.tags
}

resource "aws_s3_bucket_notification" "clean_bucket_events" {
  bucket = var.download_bucket_name

  topic {
    topic_arn = module.sns_clean_bucket_events.topic_arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [module.sns_clean_bucket_events]
}

module "sqs_clean_file_notifications" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "5.2.2"

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
          values   = [module.sns_clean_bucket_events.topic_arn]
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

module "sns_clean_file_download_notifications" {
  source  = "terraform-aws-modules/sns/aws"
  version = "7.1.0"

  name = "${local.resource_name_prefix}-clean-file-download-notifications"

  topic_policy_statements = {
    chatbot_consume = {
      actions = [
        "sns:Subscribe",
        "sns:Receive",
        "sns:Publish",
      ]
      principals = [{
        type = "Service"
        identifiers = [
          "sns.amazonaws.com",
          "events.amazonaws.com",
          "chatbot.amazonaws.com",
        ]
      }]
    }
  }

  tags = var.tags
}

module "lambda_clean_file_presigned_url_notifier" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.8.0"

  function_name                = "${local.resource_name_prefix}-clean-file-presigned-url-notifier"
  description                  = "Generates a presigned download URL for clean files and publishes it to SNS"
  handler                      = "lambda_function.lambda_handler"
  runtime                      = "python3.12"
  source_path                  = "${path.module}/lambda/clean-file-presigned-url-notifier"
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
    IDEMPOTENCY_TABLE               = module.dynamodb_idempotency.dynamodb_table_id
    MAX_DOWNLOAD_URL_EXPIRY_SECONDS = tostring(var.max_presigned_url_expiry_seconds)
    SLACK_SNS_TOPIC_ARN             = module.sns_clean_file_download_notifications.topic_arn
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
        module.dynamodb_idempotency.dynamodb_table_arn,
      ]
    }
    notification_topic_publish = {
      effect = "Allow"
      actions = [
        "sns:Publish",
      ]
      resources = [
        module.sns_clean_file_download_notifications.topic_arn,
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
  sns_topic_arns   = [module.sns_clean_file_download_notifications.topic_arn]
  tags             = var.tags
  application_name = local.resource_name_prefix
}
