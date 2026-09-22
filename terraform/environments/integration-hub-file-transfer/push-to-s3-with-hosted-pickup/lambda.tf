module "lambda_file_mover" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.8.0"

  architectures                     = ["arm64"]
  attach_tracing_policy             = true
  cloudwatch_logs_kms_key_id        = data.aws_kms_key.logs.arn
  cloudwatch_logs_retention_in_days = 90
  description                       = "Deliver clean files to isolated hosted pickup buckets"
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
    EVENT_BUS_NAME             = data.aws_cloudwatch_event_bus.file_transfer.name
    IDEMPOTENCY_EXPIRY_SECONDS = tostring(90 * 24 * 60 * 60)
    IDEMPOTENCY_TABLE          = module.dynamodb_idempotency.dynamodb_table_id
    MOVER_ROLE_MAP             = jsonencode(local.mover_role_arns_by_secret)
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
      resources = [module.sqs_hosted_pickup.queue_arn]
    }
    decrypt_queue = {
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
      resources = [module.kms_hosted_pickup_pipeline.key_arn]
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
    }, length(local.hosted_pickup_entries) == 0 ? {} : {
    read_dispatch_configuration = {
      effect    = "Allow"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = [for secret in data.aws_secretsmanager_secret.file_dispatch : secret.arn]
    }
    decrypt_dispatch_configuration = {
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
      resources = [data.aws_kms_key.secrets.arn]
    }
    assume_mover_roles = {
      effect    = "Allow"
      actions   = ["sts:AssumeRole"]
      resources = [for role in module.iam_role_mover : role.arn]
    }
  })

  tags = local.tags
}

resource "aws_lambda_event_source_mapping" "hosted_pickup" {
  event_source_arn        = module.sqs_hosted_pickup.queue_arn
  function_name           = module.lambda_file_mover.lambda_function_arn
  batch_size              = 10
  function_response_types = ["ReportBatchItemFailures"]

  scaling_config {
    maximum_concurrency = 5
  }

  lifecycle {
    precondition {
      condition     = data.aws_region.current.region == "eu-west-2"
      error_message = "push-to-s3-with-hosted-pickup supports only eu-west-2."
    }

    precondition {
      condition = alltrue([
        for bucket_name in values(local.hosted_bucket_names) :
        length(bucket_name) >= 3 && length(bucket_name) <= 63 && can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", bucket_name))
      ])
      error_message = "Hosted pickup bucket names must be valid 3-63 character S3 bucket names."
    }

    precondition {
      condition = alltrue([
        for entry in values(local.hosted_pickup_entries) :
        !startswith(entry.action.push_to_s3_with_hosted_pickup.destination_prefix, "/") &&
        (entry.action.push_to_s3_with_hosted_pickup.destination_prefix == "" || endswith(entry.action.push_to_s3_with_hosted_pickup.destination_prefix, "/"))
      ])
      error_message = "Hosted pickup destination prefixes must be empty or end with '/', and must not start with '/'."
    }

    precondition {
      condition = alltrue([
        for entry in values(local.hosted_pickup_entries) :
        try(entry.action.push_to_s3_with_hosted_pickup.retention_days, 0) >= 1 &&
        floor(try(entry.action.push_to_s3_with_hosted_pickup.retention_days, 0)) == try(entry.action.push_to_s3_with_hosted_pickup.retention_days, 0)
      ])
      error_message = "Hosted pickup retention_days must be a positive whole number."
    }
  }
}