# Lambda which notifies step function when DMS task stops
module "step_function_notification_lambda" {
  source = "../../lambdas/generic"

  enable_lambda = var.setup_step_function_notification_lambda
  name          = var.step_function_notification_lambda
  s3_bucket     = var.s3_file_transfer_lambda_code_s3_bucket
  s3_key        = var.reporting_lambda_code_s3_key
  handler       = var.step_function_notification_lambda_handler
  runtime       = var.step_function_notification_lambda_runtime
  policies      = var.step_function_notification_lambda_policies
  tracing       = var.step_function_notification_lambda_tracing
  timeout       = 300 # 5 minutes

  log_retention_in_days = var.lambda_log_retention_in_days

  vpc_settings = {
    subnet_ids         = var.lambda_subnet_ids         # NEW
    security_group_ids = var.lambda_security_group_ids # NEW
  }

  tags = merge(
    var.tags,
    {
      Resource_Group = "ingestion-pipeline"
      Resource_Type  = "Lambda"
      Name           = var.step_function_notification_lambda
    }
  )
}

module "step_function_notification_lambda_trigger" {
  source = "../../lambda_trigger"

  enable_lambda_trigger = var.setup_step_function_notification_lambda

  event_name           = var.step_function_notification_lambda_trigger
  lambda_function_arn  = module.step_function_notification_lambda.lambda_function
  lambda_function_name = module.step_function_notification_lambda.lambda_name

  trigger_event_pattern = jsonencode(
    {
      "source" : ["aws.dms"],
      "detail-type" : ["DMS Replication Task State Change"],
      "detail" : {
        "type" : ["REPLICATION_TASK"],
        "eventType" : ["REPLICATION_TASK_STOPPED", "REPLICATION_TASK_FAILED"]
      }
    }
  )
}
