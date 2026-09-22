module "lambda_file_mover" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.8.0"

  architectures                     = ["arm64"]
  attach_tracing_policy             = true
  cloudwatch_logs_kms_key_id        = data.aws_kms_key.logs.arn
  cloudwatch_logs_retention_in_days = 90
  description                       = "Deliver clean files to configured customer S3 destinations"
  function_name                     = local.pattern_name
  handler                           = "handler.lambda_handler"
  memory_size                       = 512
  reserved_concurrent_executions    = 5
  role_name                         = local.lambda_role_name
  runtime                           = "python3.12"
  source_path                       = "lambda/file-mover"
  timeout                           = 300
  tracing_mode                      = "Active"
  trigger_on_package_timestamp      = false

  environment_variables = {
    AUTHORISED_DESTINATION_MAP = jsonencode(local.authorised_destinations_by_secret)
    DELIVERY_ROLE_MAP          = jsonencode(local.delivery_role_arns_by_secret)
    EVENT_BUS_NAME             = data.aws_cloudwatch_event_bus.file_transfer.name
    IDEMPOTENCY_EXPIRY_SECONDS = tostring(90 * 24 * 60 * 60)
    IDEMPOTENCY_TABLE          = module.dynamodb_idempotency.dynamodb_table_id
    POWERTOOLS_LOG_LEVEL       = "INFO"
    POWERTOOLS_SERVICE_NAME    = local.pattern_name
    SOURCE_PREFIX_MAP          = jsonencode(local.source_prefixes_by_secret)
    SUPPORTED_REGION           = "eu-west-2"
  }

  attach_policy_statements = true
  policy_statements = merge({
    consume_queue = {
      effect = "Allow"
      actions = [
        "sqs:ChangeMessageVisibility",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:ReceiveMessage",
      ]
      resources = [module.sqs_push_to_s3.queue_arn]
    }
    decrypt_queue = {
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
      resources = [module.kms_push_to_s3.key_arn]
    }
    publish_completion = {
      effect    = "Allow"
      actions   = ["events:PutEvents"]
      resources = [data.aws_cloudwatch_event_bus.file_transfer.arn]
    }
    use_idempotency_table = {
      effect = "Allow"
      actions = [
        "dynamodb:DeleteItem",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
      ]
      resources = [module.dynamodb_idempotency.dynamodb_table_arn]
    }
    }, length(local.push_to_s3_entries) == 0 ? {} : {
    read_source_versions = {
      effect    = "Allow"
      actions   = ["s3:GetObjectVersion"]
      resources = local.source_object_arns
    }
    decrypt_source = {
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
      resources = [data.aws_kms_key.clean.arn]
    }
    read_dispatch_configuration = {
      effect    = "Allow"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = [for secret_arn_prefix in values(local.push_to_s3_secret_arn_prefixes) : "${secret_arn_prefix}??????"]
    }
    decrypt_dispatch_configuration = {
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
      resources = [data.aws_kms_key.secrets.arn]
    }
    assume_delivery_roles = {
      effect    = "Allow"
      actions   = ["sts:AssumeRole"]
      resources = [for role in module.iam_role_delivery : role.arn]
    }
  })

  tags = local.tags
}

resource "aws_lambda_event_source_mapping" "push_to_s3" {
  event_source_arn        = module.sqs_push_to_s3.queue_arn
  function_name           = module.lambda_file_mover.lambda_function_arn
  batch_size              = 10
  function_response_types = ["ReportBatchItemFailures"]

  scaling_config {
    maximum_concurrency = 5
  }

  lifecycle {
    precondition {
      condition = alltrue([
        for entry in values(local.push_to_s3_entries) :
        try(entry.action.push_to_s3.bucket_region, "eu-west-2") == "eu-west-2"
      ])
      error_message = "push-to-s3 supports only the eu-west-2 destination region."
    }

    precondition {
      condition = alltrue([
        for entry in values(local.push_to_s3_entries) :
        !startswith(entry.action.push_to_s3.destination_prefix, "/") &&
        (entry.action.push_to_s3.destination_prefix == "" || endswith(entry.action.push_to_s3.destination_prefix, "/"))
      ])
      error_message = "push-to-s3 destination prefixes must be empty or end with '/', and must not start with '/'."
    }
  }
}