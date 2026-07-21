module "lambda_file_received_adapter" {
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
  }



  tags = local.tags
}

module "lambda_file_scan_result_recorded_adapter" {
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
    AWS_ACCOUNT_ID                          = data.aws_caller_identity.current.account_id
    EVENT_BUS_ARN                           = module.eventbridge_file_transfer_bus.eventbridge_bus_arn
    IDEMPOTENCY_EXPIRY_SECONDS              = tostring(local.cloudwatch_retention_days * 24 * 60 * 60)
    IDEMPOTENCY_TABLE                       = module.dynamodb_adapter_idempotency.dynamodb_table_id
    MALWARE_PROTECTION_PLAN_ARN             = aws_guardduty_malware_protection_plan.this.arn
    PROCESSING_BUCKET_NAME                  = module.s3_bucket["processing"].s3_bucket_id
    PROCESSING_OBJECT_LOOKUP_KEY_INDEX_NAME = "processing-object-lookup-key-index"
    POWERTOOLS_LOG_LEVEL                    = "INFO"
    POWERTOOLS_SERVICE_NAME                 = "integration-hub-file-transfer-file-scan-result-recorded-adapter"
    WORKFLOW_IDEMPOTENCY_TABLE              = module.dynamodb_file_transfer_workflow_idempotency.dynamodb_table_id
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
    lookup_workflow_record = {
      effect    = "Allow"
      actions   = ["dynamodb:Query"]
      resources = ["${module.dynamodb_file_transfer_workflow_idempotency.dynamodb_table_arn}/index/processing-object-lookup-key-index"]
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