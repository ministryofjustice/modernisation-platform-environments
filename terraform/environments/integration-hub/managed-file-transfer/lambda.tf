module "lambda_unscanned_to_processing" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.8.0"

  function_name                  = "${local.application_name}-unscanned-to-processing"
  architectures                  = ["arm64"]
  description                    = "Moves uploaded files from the unscanned bucket to the processing bucket"
  handler                        = "lambda_function.lambda_handler"
  memory_size                    = 256
  reserved_concurrent_executions = 10
  runtime                        = "python3.12"
  source_path                    = "lambda/s3-file-mover"
  timeout                        = 30
  tracing_mode                   = "Active"

  event_source_mapping = {
    sqs = {
      event_source_arn = module.sqs_unscanned_s3_notifications.queue_arn
      batch_size       = 1
      scaling_config = {
        maximum_concurrency = 10
      }
    }
  }

  environment_variables = {
    DESTINATION_BUCKET_NAME = module.s3_bucket["processing"].s3_bucket_id
    IDEMPOTENCY_TABLE       = module.dynamodb_idempotency.dynamodb_table_id
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

  attach_policies       = true
  attach_tracing_policy = true
  number_of_policies    = 1
  policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole",
  ]

  cloudwatch_logs_kms_key_id        = module.kms_cloudwatch_logs.key_arn
  cloudwatch_logs_retention_in_days = 30

  tags = local.tags
}

module "lambda_processing_to_post_scan" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.8.0"

  function_name                  = "${local.application_name}-processing-to-post-scan"
  architectures                  = ["arm64"]
  description                    = "Moves scanned files from the processing bucket to the post-scan destination bucket"
  handler                        = "lambda_function.lambda_handler"
  memory_size                    = 256
  reserved_concurrent_executions = 10
  runtime                        = "python3.12"
  source_path                    = "lambda/guard-duty-file-mover"
  timeout                        = 30
  tracing_mode                   = "Active"

  event_source_mapping = {
    sqs = {
      event_source_arn = module.sqs_guard_duty_malware_protection_for_s3_events.queue_arn
      batch_size       = 1
      scaling_config = {
        maximum_concurrency = 10
      }
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

  attach_policies       = true
  attach_tracing_policy = true
  number_of_policies    = 1
  policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole",
  ]

  cloudwatch_logs_kms_key_id        = module.kms_cloudwatch_logs.key_arn
  cloudwatch_logs_retention_in_days = 30

  tags = local.tags
}
