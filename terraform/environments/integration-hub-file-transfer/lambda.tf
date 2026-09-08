module "lambda_file_received_adapter" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.8.0"

  architectures                     = ["arm64"]
  attach_dead_letter_policy         = true
  attach_tracing_policy             = true
  cloudwatch_logs_kms_key_id        = module.kms_cloudwatch_logs.key_arn
  cloudwatch_logs_retention_in_days = local.cloudwatch_retention_days
  create_async_event_config         = true
  dead_letter_target_arn            = module.sqs_lambda_file_received_adapter_dlq.queue_arn
  description                       = "Transforms incoming S3 Object Created notifications into FileReceived.v1 events"
  function_name                     = "${local.application_name}-file-received-adapter"
  handler                           = "lambda_function.lambda_handler"
  maximum_event_age_in_seconds      = 21600
  maximum_retry_attempts            = 2
  memory_size                       = 128
  reserved_concurrent_executions    = 10
  runtime                           = "python3.12"
  source_path                       = "lambda/file-received-adapter"
  timeout                           = 30
  tracing_mode                      = "Active"
  trigger_on_package_timestamp      = false

  environment_variables = {
    EVENT_BUS_ARN              = module.eventbridge_file_transfer_bus.eventbridge_bus_arn
    IDEMPOTENCY_EXPIRY_SECONDS = tostring(local.cloudwatch_retention_days * 24 * 60 * 60)
    IDEMPOTENCY_TABLE          = module.dynamodb_adapter_idempotency.dynamodb_table_id
    INCOMING_BUCKET_NAME       = module.s3_bucket["incoming"].s3_bucket_id
    POWERTOOLS_LOG_LEVEL       = "INFO"
    POWERTOOLS_SERVICE_NAME    = "integration-hub-file-transfer-file-received-adapter"
  }

  attach_policy_statements = true
  policy_statements = {
    publish_file_received_events = {
      effect    = "Allow"
      actions   = ["events:PutEvents"]
      resources = [module.eventbridge_file_transfer_bus.eventbridge_bus_arn]
    }
    use_idempotency_table = {
      effect = "Allow"
      actions = [
        "dynamodb:DeleteItem",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
      ]
      resources = [module.dynamodb_adapter_idempotency.dynamodb_table_arn]
    }
    use_dlq_key = {
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:GenerateDataKey",
      ]
      resources = [module.kms_sqs.key_arn]
    }
  }



  tags = local.tags
}

module "lambda_file_scan_result_recorded_adapter" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.8.0"

  architectures                     = ["arm64"]
  attach_dead_letter_policy         = true
  attach_tracing_policy             = true
  cloudwatch_logs_kms_key_id        = module.kms_cloudwatch_logs.key_arn
  cloudwatch_logs_retention_in_days = local.cloudwatch_retention_days
  create_async_event_config         = true
  dead_letter_target_arn            = module.sqs_lambda_file_scan_result_recorded_adapter_dlq.queue_arn
  description                       = "Transforms GuardDuty malware scan results into FileScanResultRecorded.v1 events"
  function_name                     = "${local.application_name}-file-scan-result-recorded-adapter"
  handler                           = "lambda_function.lambda_handler"
  maximum_event_age_in_seconds      = 21600
  maximum_retry_attempts            = 2
  memory_size                       = 128
  reserved_concurrent_executions    = 10
  runtime                           = "python3.12"
  source_path                       = "lambda/file-scan-result-recorded-adapter"
  timeout                           = 30
  tracing_mode                      = "Active"
  trigger_on_package_timestamp      = false

  environment_variables = {
    AWS_ACCOUNT_ID             = data.aws_caller_identity.current.account_id
    EVENT_BUS_ARN              = module.eventbridge_file_transfer_bus.eventbridge_bus_arn
    IDEMPOTENCY_EXPIRY_SECONDS = tostring(local.cloudwatch_retention_days * 24 * 60 * 60)
    IDEMPOTENCY_TABLE          = module.dynamodb_adapter_idempotency.dynamodb_table_id
    POWERTOOLS_LOG_LEVEL       = "INFO"
    POWERTOOLS_SERVICE_NAME    = "integration-hub-file-transfer-file-scan-result-recorded-adapter"
    WORKFLOW_IDEMPOTENCY_TABLE = module.dynamodb_file_transfer_idempotency.dynamodb_table_id
  }

  attach_policy_statements = true
  policy_statements = {
    publish_file_scan_result_events = {
      effect    = "Allow"
      actions   = ["events:PutEvents"]
      resources = [module.eventbridge_file_transfer_bus.eventbridge_bus_arn]
    }
    use_idempotency_table = {
      effect = "Allow"
      actions = [
        "dynamodb:DeleteItem",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
      ]
      resources = [module.dynamodb_adapter_idempotency.dynamodb_table_arn]
    }
    read_staging_record = {
      effect    = "Allow"
      actions   = ["dynamodb:GetItem"]
      resources = [module.dynamodb_file_transfer_idempotency.dynamodb_table_arn]
    }
    read_processing_object = {
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:GetObjectTagging",
        "s3:GetObjectVersion",
        "s3:GetObjectVersionTagging",
      ]
      resources = ["${module.s3_bucket["processing"].s3_bucket_arn}/*"]
    }
    use_dlq_key = {
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:GenerateDataKey",
      ]
      resources = [module.kms_sqs.key_arn]
    }
  }

  tags = local.tags
}

module "lambda_stage" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.8.0"

  architectures                     = ["arm64"]
  attach_dead_letter_policy         = true
  attach_tracing_policy             = true
  cloudwatch_logs_kms_key_id        = module.kms_cloudwatch_logs.key_arn
  cloudwatch_logs_retention_in_days = local.cloudwatch_retention_days
  create_async_event_config         = true
  dead_letter_target_arn            = module.sqs_lambda_stage_dlq.queue_arn
  description                       = "Copies exact incoming object versions to processing for malware scanning"
  function_name                     = "${local.application_name}-stage"
  handler                           = "stage_lambda.lambda_handler"
  maximum_event_age_in_seconds      = 21600
  maximum_retry_attempts            = 2
  memory_size                       = 1024
  reserved_concurrent_executions    = 10
  runtime                           = "python3.12"
  source_path                       = "lambda/file-mover"
  timeout                           = 900
  tracing_mode                      = "Active"
  trigger_on_package_timestamp      = false

  environment_variables = {
    AWS_ACCOUNT_ID               = data.aws_caller_identity.current.account_id
    EVENT_BUS_ARN                = module.eventbridge_file_transfer_bus.eventbridge_bus_arn
    IDEMPOTENCY_EXPIRY_SECONDS   = tostring(local.cloudwatch_retention_days * 24 * 60 * 60)
    IDEMPOTENCY_TABLE            = module.dynamodb_adapter_idempotency.dynamodb_table_id
    INCOMING_BUCKET_NAME         = module.s3_bucket["incoming"].s3_bucket_id
    INCOMING_KMS_KEY_ARN         = module.kms_s3_bucket["incoming"].key_arn
    MULTIPART_MAX_PARTS          = "1000"
    MULTIPART_PART_SIZE_BYTES    = "1073741824"
    MULTIPART_WORKERS            = "4"
    POWERTOOLS_LOG_LEVEL         = "INFO"
    POWERTOOLS_METRICS_NAMESPACE = "IntegrationHubFileTransfer"
    POWERTOOLS_SERVICE_NAME      = "integration-hub-file-transfer-stage"
    PROCESSING_BUCKET_NAME       = module.s3_bucket["processing"].s3_bucket_id
    PROCESSING_KMS_KEY_ARN       = module.kms_s3_bucket["processing"].key_arn
    RECEIPT                      = "false"
    WORKFLOW_IDEMPOTENCY_TABLE   = module.dynamodb_file_transfer_idempotency.dynamodb_table_id
  }

  attach_policy_statements = true
  policy_statements = {
    publish_completion_events = {
      effect    = "Allow"
      actions   = ["events:PutEvents"]
      resources = [module.eventbridge_file_transfer_bus.eventbridge_bus_arn]
    }
    use_idempotency_tables = {
      effect = "Allow"
      actions = [
        "dynamodb:DeleteItem",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
      ]
      resources = [
        module.dynamodb_adapter_idempotency.dynamodb_table_arn,
        module.dynamodb_file_transfer_idempotency.dynamodb_table_arn,
      ]
    }
    list_source_and_destination_versions = {
      effect  = "Allow"
      actions = ["s3:ListBucketVersions"]
      resources = [
        module.s3_bucket["incoming"].s3_bucket_arn,
        module.s3_bucket["processing"].s3_bucket_arn,
      ]
    }
    read_and_delete_incoming_versions = {
      effect = "Allow"
      actions = [
        "s3:DeleteObjectVersion",
        "s3:GetObject",
        "s3:GetObjectTagging",
        "s3:GetObjectVersion",
        "s3:GetObjectVersionTagging",
      ]
      resources = ["${module.s3_bucket["incoming"].s3_bucket_arn}/*"]
    }
    create_incoming_receipts = {
      effect = "Allow"
      actions = [
        "s3:PutObject",
        "s3:PutObjectTagging",
      ]
      resources = ["${module.s3_bucket["incoming"].s3_bucket_arn}/*.receipt"]
    }
    manage_processing_versions = {
      effect = "Allow"
      actions = [
        "s3:AbortMultipartUpload",
        "s3:GetObject",
        "s3:GetObjectTagging",
        "s3:GetObjectVersion",
        "s3:GetObjectVersionTagging",
        "s3:ListMultipartUploadParts",
        "s3:PutObject",
        "s3:PutObjectTagging",
      ]
      resources = ["${module.s3_bucket["processing"].s3_bucket_arn}/*"]
    }
    use_s3_and_dlq_keys = {
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:GenerateDataKey*",
        "kms:ReEncrypt*",
      ]
      resources = [
        module.kms_s3_bucket["incoming"].key_arn,
        module.kms_s3_bucket["processing"].key_arn,
        module.kms_sqs.key_arn,
      ]
    }
  }

  tags = local.tags
}

module "lambda_route" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.8.0"

  architectures                     = ["arm64"]
  attach_dead_letter_policy         = true
  attach_tracing_policy             = true
  cloudwatch_logs_kms_key_id        = module.kms_cloudwatch_logs.key_arn
  cloudwatch_logs_retention_in_days = local.cloudwatch_retention_days
  create_async_event_config         = true
  dead_letter_target_arn            = module.sqs_lambda_route_dlq.queue_arn
  description                       = "Routes exact processing object versions according to the current malware scan result"
  function_name                     = "${local.application_name}-route"
  handler                           = "route_lambda.lambda_handler"
  maximum_event_age_in_seconds      = 21600
  maximum_retry_attempts            = 2
  memory_size                       = 1024
  reserved_concurrent_executions    = 10
  runtime                           = "python3.12"
  source_path                       = "lambda/file-mover"
  timeout                           = 900
  tracing_mode                      = "Active"
  trigger_on_package_timestamp      = false

  environment_variables = {
    AWS_ACCOUNT_ID               = data.aws_caller_identity.current.account_id
    CLEAN_BUCKET_NAME            = module.s3_bucket["clean"].s3_bucket_id
    CLEAN_KMS_KEY_ARN            = module.kms_s3_bucket["clean"].key_arn
    EVENT_BUS_ARN                = module.eventbridge_file_transfer_bus.eventbridge_bus_arn
    IDEMPOTENCY_EXPIRY_SECONDS   = tostring(local.cloudwatch_retention_days * 24 * 60 * 60)
    IDEMPOTENCY_TABLE            = module.dynamodb_adapter_idempotency.dynamodb_table_id
    INVESTIGATION_BUCKET_NAME    = module.s3_bucket["investigation"].s3_bucket_id
    INVESTIGATION_KMS_KEY_ARN    = module.kms_s3_bucket["investigation"].key_arn
    MULTIPART_MAX_PARTS          = "1000"
    MULTIPART_PART_SIZE_BYTES    = "1073741824"
    MULTIPART_WORKERS            = "4"
    POWERTOOLS_LOG_LEVEL         = "INFO"
    POWERTOOLS_METRICS_NAMESPACE = "IntegrationHubFileTransfer"
    POWERTOOLS_SERVICE_NAME      = "integration-hub-file-transfer-route"
    PROCESSING_BUCKET_NAME       = module.s3_bucket["processing"].s3_bucket_id
    QUARANTINE_BUCKET_NAME       = module.s3_bucket["quarantine"].s3_bucket_id
    QUARANTINE_KMS_KEY_ARN       = module.kms_s3_bucket["quarantine"].key_arn
    WORKFLOW_IDEMPOTENCY_TABLE   = module.dynamodb_file_transfer_idempotency.dynamodb_table_id
  }

  attach_policy_statements = true
  policy_statements = {
    publish_completion_events = {
      effect    = "Allow"
      actions   = ["events:PutEvents"]
      resources = [module.eventbridge_file_transfer_bus.eventbridge_bus_arn]
    }
    use_idempotency_tables = {
      effect = "Allow"
      actions = [
        "dynamodb:DeleteItem",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
      ]
      resources = [
        module.dynamodb_adapter_idempotency.dynamodb_table_arn,
        module.dynamodb_file_transfer_idempotency.dynamodb_table_arn,
      ]
    }
    list_source_and_destination_versions = {
      effect  = "Allow"
      actions = ["s3:ListBucketVersions"]
      resources = [
        for key in ["processing", "clean", "quarantine", "investigation"] :
        module.s3_bucket[key].s3_bucket_arn
      ]
    }
    read_and_delete_processing_versions = {
      effect = "Allow"
      actions = [
        "s3:DeleteObjectVersion",
        "s3:GetObject",
        "s3:GetObjectTagging",
        "s3:GetObjectVersion",
        "s3:GetObjectVersionTagging",
      ]
      resources = ["${module.s3_bucket["processing"].s3_bucket_arn}/*"]
    }
    manage_destination_versions = {
      effect = "Allow"
      actions = [
        "s3:AbortMultipartUpload",
        "s3:GetObject",
        "s3:GetObjectTagging",
        "s3:GetObjectVersion",
        "s3:GetObjectVersionTagging",
        "s3:ListMultipartUploadParts",
        "s3:PutObject",
        "s3:PutObjectTagging",
      ]
      resources = [
        for key in ["clean", "quarantine", "investigation"] :
        "${module.s3_bucket[key].s3_bucket_arn}/*"
      ]
    }
    use_s3_and_dlq_keys = {
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:GenerateDataKey*",
        "kms:ReEncrypt*",
      ]
      resources = concat(
        [module.kms_sqs.key_arn],
        [
          for key in ["processing", "clean", "quarantine", "investigation"] :
          module.kms_s3_bucket[key].key_arn
        ],
      )
    }
  }

  tags = local.tags
}

module "lambda_file_action_execution_requested_adapter" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.8.0"

  architectures                     = ["arm64"]
  attach_dead_letter_policy         = true
  attach_tracing_policy             = true
  cloudwatch_logs_kms_key_id        = module.kms_cloudwatch_logs.key_arn
  cloudwatch_logs_retention_in_days = local.cloudwatch_retention_days
  create_async_event_config         = true
  dead_letter_target_arn            = module.sqs_lambda_file_action_execution_requested_adapter_dlq.queue_arn
  description                       = "Transforms configured FileRouted.v1 events into FileActionExecutionRequested.v1 events"
  function_name                     = "file-action-execution-requested-adapter"
  handler                           = "lambda_function.lambda_handler"
  maximum_event_age_in_seconds      = 21600
  maximum_retry_attempts            = 2
  memory_size                       = 128
  reserved_concurrent_executions    = 10
  runtime                           = "python3.12"
  source_path                       = "lambda/file-action-execution-requested-adapter"
  timeout                           = 30
  tracing_mode                      = "Active"
  trigger_on_package_timestamp      = false

  environment_variables = {
    DISPATCH_SECRET_NAME_PREFIX = local.file_dispatch_secret_name_prefix
    EVENT_BUS_ARN               = module.eventbridge_file_transfer_bus.eventbridge_bus_arn
    IDEMPOTENCY_EXPIRY_SECONDS  = tostring(local.cloudwatch_retention_days * 24 * 60 * 60)
    IDEMPOTENCY_TABLE           = module.dynamodb_adapter_idempotency.dynamodb_table_id
    POWERTOOLS_LOG_LEVEL        = "INFO"
    POWERTOOLS_SERVICE_NAME     = "file-action-execution-requested-adapter"
  }

  attach_policy_statements = true
  policy_statements = {
    publish_action_requests = {
      effect    = "Allow"
      actions   = ["events:PutEvents"]
      resources = [module.eventbridge_file_transfer_bus.eventbridge_bus_arn]
    }
    use_idempotency_table = {
      effect = "Allow"
      actions = [
        "dynamodb:DeleteItem",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
      ]
      resources = [module.dynamodb_adapter_idempotency.dynamodb_table_arn]
    }
    read_dispatch_configuration = {
      effect  = "Allow"
      actions = ["secretsmanager:GetSecretValue"]
      resources = [
        "arn:aws:secretsmanager:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:secret:${local.file_dispatch_secret_name_prefix}*",
      ]
    }
    decrypt_dispatch_configuration = {
      effect    = "Allow"
      actions   = ["kms:Decrypt", "kms:DescribeKey"]
      resources = [module.kms_secrets.key_arn]
    }
    use_dlq_key = {
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:GenerateDataKey*",
      ]
      resources = [module.kms_sqs.key_arn]
    }
  }

  tags = local.tags
}

# Module-managed allowed_triggers would create a cycle between the Lambda and EventBridge target.
resource "aws_lambda_permission" "eventbridge_file_received_adapter" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_file_received_adapter.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = module.eventbridge_default_bus.eventbridge_rule_arns["incoming-s3-object-created"]
}

resource "aws_lambda_permission" "eventbridge_file_scan_result_recorded_adapter" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_file_scan_result_recorded_adapter.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = module.eventbridge_default_bus.eventbridge_rule_arns["guardduty-malware-scan-result"]
}

resource "aws_lambda_permission" "eventbridge_stage" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_stage.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = module.eventbridge_file_transfer_bus.eventbridge_rule_arns["file-transfer-workflow"]
}

resource "aws_lambda_permission" "eventbridge_route" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_route.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = module.eventbridge_file_transfer_bus.eventbridge_rule_arns["file-routing-workflow"]
}

resource "aws_lambda_permission" "eventbridge_file_action_execution_requested_adapter" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_file_action_execution_requested_adapter.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = module.eventbridge_file_transfer_bus.eventbridge_rule_arns["file-action-dispatch-workflow"]
}
