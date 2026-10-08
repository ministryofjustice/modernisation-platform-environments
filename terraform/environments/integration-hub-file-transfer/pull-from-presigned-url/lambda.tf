module "lambda_notifier" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source        = "terraform-aws-modules/lambda/aws"
  version       = "8.9.0"
  function_name = local.pattern_name
  role_name     = local.pattern_name
  description   = "Notify recipients in Slack with an authenticated MFT portal link"
  runtime       = "python3.12"
  architectures = ["arm64"]
  handler       = "handler.lambda_handler"
  source_path   = [{ path = "${path.module}/lambda/notifier", patterns = ["!tests/.*", "!.*__pycache__/.*"] }]
  # Match the other delivery components: the content-derived package filename
  # tracks code changes without comparing rebuilt ZIP bytes during apply.
  ignore_source_code_hash           = true
  trigger_on_package_timestamp      = false
  timeout                           = 900
  memory_size                       = 512
  cloudwatch_logs_retention_in_days = 90
  cloudwatch_logs_kms_key_id        = data.aws_kms_key.logs.arn
  attach_tracing_policy             = true
  tracing_mode                      = "Active"
  environment_variables = {
    IDEMPOTENCY_TABLE = module.dynamodb_notifications.dynamodb_table_id
    CONFIG = jsonencode({
      queue_arn      = module.sqs_notifications.queue_arn
      topic_arn      = module.sns_notifications.topic_arn
      account        = data.aws_caller_identity.current.account_id
      clean_bucket   = "${local.application_name}-${local.environment}-clean"
      portal_url     = local.portal_url
      routes         = local.routes
      pickup_bucket  = module.s3_pickup.s3_bucket_id
      pickup_kms_key = module.kms_notifications_pipeline.key_arn
    })
  }
  attach_policy_statements = true
  policy_statements = merge({
    queue = {
      actions   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes", "sqs:ChangeMessageVisibility"]
      resources = [module.sqs_notifications.queue_arn]
    }
    decrypt = {
      actions   = ["kms:Decrypt"]
      resources = [module.kms_notifications_pipeline.key_arn]
    }
    deduplicate = {
      actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem"]
      resources = [module.dynamodb_notifications.dynamodb_table_arn]
    }
    }, length(local.recipients) == 0 ? {} : {
    read_clean = {
      actions   = ["s3:GetObjectVersion"]
      resources = [for recipient in local.recipients : "arn:aws:s3:::${local.application_name}-${local.environment}-clean/${recipient.prefix}*"]
    }
    decrypt_clean = {
      actions   = ["kms:Decrypt"]
      resources = [data.aws_kms_key.clean.arn]
    }
    retain_pickup = {
      actions   = ["s3:PutObject", "s3:AbortMultipartUpload"]
      resources = ["${module.s3_pickup.s3_bucket_arn}/*"]
    }
    encrypt_pickup = {
      actions   = ["kms:GenerateDataKey"]
      resources = [module.kms_notifications_pipeline.key_arn]
    }
    secrets = {
      actions = ["secretsmanager:GetSecretValue"]
      resources = concat([for secret in data.aws_secretsmanager_secret.dispatch : secret.arn],
      [for secret in aws_secretsmanager_secret.webhook : secret.arn])
    }
    decrypt_secrets = {
      actions   = ["kms:Decrypt"]
      resources = [data.aws_kms_key.secrets.arn]
    }
  })
  tags = local.tags
}

resource "aws_lambda_event_source_mapping" "notifications" {
  event_source_arn        = module.sqs_notifications.queue_arn
  function_name           = module.lambda_notifier.lambda_function_arn
  batch_size              = 1
  function_response_types = ["ReportBatchItemFailures"]
  scaling_config { maximum_concurrency = 2 }
  # Empty configuration deploys an inert pipeline, with no recipient access.
  enabled = length(local.recipients) > 0
}
