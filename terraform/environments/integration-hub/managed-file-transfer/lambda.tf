module "lambda_unscanned_to_processing" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.8.0"

  function_name                = "${local.application_name}-unscanned-to-processing"
  description                  = "Moves uploaded files from the unscanned bucket to the processing bucket"
  handler                      = "lambda_function.lambda_handler"
  runtime                      = "python3.12"
  source_path                  = "lambda/s3-file-mover"
  trigger_on_package_timestamp = false

  event_source_mapping = {
    sqs = {
      event_source_arn = module.sqs_transfer_notifications.queue_arn
      batch_size       = 1
    }
  }

  environment_variables = {
    DESTINATION_BUCKET_NAME = module.s3_bucket["processing"].s3_bucket_id
    IDEMPOTENCY_TABLE       = module.dynamodb_idempotency.dynamodb_table_id
    SOURCE_BUCKET_NAME      = module.s3_bucket["unscanned"].s3_bucket_id
  }

  attach_policy_statements = true
  policy_statements = {
    source_bucket_get_delete = {
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetObjectTagging",
        "s3:GetObjectVersionTagging",
        "s3:DeleteObject",
        "s3:DeleteObjectVersion",
      ]
      resources = [
        "${module.s3_bucket["unscanned"].s3_bucket_arn}/*",
      ]
    }
    destination_bucket_write = {
      effect = "Allow"
      actions = [
        "s3:PutObject",
        "s3:PutObjectTagging",
        "s3:PutObjectVersionTagging",
      ]
      resources = [
        "${module.s3_bucket["processing"].s3_bucket_arn}/*",
      ]
    }
    bucket_kms_access = {
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:GenerateDataKey*",
        "kms:ReEncrypt*",
      ]
      resources = [
        module.kms_s3_bucket["unscanned"].key_arn,
        module.kms_s3_bucket["processing"].key_arn,
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
  }

  attach_policies    = true
  number_of_policies = 1
  policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole",
  ]

  cloudwatch_logs_retention_in_days = 30

  tags = local.tags
}

module "lambda_processing_to_post_scan" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.8.0"

  function_name                = "${local.application_name}-processing-to-post-scan"
  description                  = "Moves scanned files from the processing bucket to the post-scan destination bucket"
  handler                      = "lambda_function.lambda_handler"
  runtime                      = "python3.12"
  source_path                  = "lambda/guard-duty-file-mover"
  trigger_on_package_timestamp = false

  event_source_mapping = {
    sqs = {
      event_source_arn = module.sqs_guard_duty_malware_protection_for_s3_events.queue_arn
      batch_size       = 1
    }
  }

  environment_variables = {
    BUCKET_NAMES_BY_KEY = jsonencode({
      processing    = module.s3_bucket["processing"].s3_bucket_id
      clean         = module.s3_bucket["clean"].s3_bucket_id
      quarantine    = module.s3_bucket["quarantine"].s3_bucket_id
      investigation = module.s3_bucket["investigation"].s3_bucket_id
    })
    DEFAULT_SOURCE_BUCKET_KEY = local.iam_configuration.malware_scanning_processing_bucket_key
    IDEMPOTENCY_TABLE         = module.dynamodb_idempotency.dynamodb_table_id
  }

  attach_policy_statements = true
  policy_statements = {
    source_bucket_read_delete = {
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetObjectTagging",
        "s3:GetObjectVersionTagging",
        "s3:DeleteObject",
        "s3:DeleteObjectVersion",
      ]
      resources = [
        "${module.s3_bucket["processing"].s3_bucket_arn}/*",
      ]
    }
    destination_bucket_write = {
      effect = "Allow"
      actions = [
        "s3:PutObject",
        "s3:PutObjectTagging",
        "s3:PutObjectVersionTagging",
      ]
      resources = [
        "${module.s3_bucket["clean"].s3_bucket_arn}/*",
        "${module.s3_bucket["quarantine"].s3_bucket_arn}/*",
        "${module.s3_bucket["investigation"].s3_bucket_arn}/*",
      ]
    }
    bucket_kms_access = {
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:GenerateDataKey*",
        "kms:ReEncrypt*",
      ]
      resources = [
        module.kms_s3_bucket["clean"].key_arn,
        module.kms_s3_bucket["investigation"].key_arn,
        module.kms_s3_bucket["processing"].key_arn,
        module.kms_s3_bucket["quarantine"].key_arn,
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
  }

  attach_policies    = true
  number_of_policies = 1
  policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole",
  ]

  cloudwatch_logs_retention_in_days = 30

  tags = local.tags
}

module "lambda_clean_file_presigned_url_notifier" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.8.0"

  function_name                = "${local.application_name}-clean-file-presigned-url-notifier"
  description                  = "Generates a presigned download URL for clean files and publishes it to SNS"
  handler                      = "lambda_function.lambda_handler"
  runtime                      = "python3.12"
  source_path                  = "lambda/clean-file-presigned-url-notifier"
  trigger_on_package_timestamp = false

  event_source_mapping = {
    sqs = {
      event_source_arn = module.sqs_clean_file_notifications.queue_arn
      batch_size       = 1
    }
  }

  environment_variables = {
    DOWNLOAD_BUCKET_NAME            = module.s3_bucket["clean"].s3_bucket_id
    DOWNLOAD_URL_EXPIRY_SECONDS     = tostring(local.notification_configuration.presigned_url_expiry_seconds)
    IDEMPOTENCY_TABLE               = module.dynamodb_idempotency.dynamodb_table_id
    MAX_DOWNLOAD_URL_EXPIRY_SECONDS = tostring(local.notification_configuration.max_presigned_url_expiry_seconds)
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
        "${module.s3_bucket["clean"].s3_bucket_arn}/*",
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
        module.kms_s3_bucket["clean"].key_arn,
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

  tags = local.tags
}
