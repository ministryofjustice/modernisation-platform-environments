module "redshift_table_expiry_lambda" {
  source = "./modules/lambdas/generic"

  enable_lambda  = local.lambda_redshift_table_expiry_enabled
  name           = local.lambda_redshift_table_expiry_name
  s3_bucket      = local.lambda_redshift_table_expiry_code_s3_bucket
  s3_key         = local.lambda_redshift_table_expiry_code_s3_key
  handler        = local.lambda_redshift_table_expiry_handler
  runtime        = local.lambda_redshift_table_expiry_runtime
  policies       = local.lambda_redshift_table_expiry_policies
  tracing        = local.lambda_redshift_table_expiry_tracing
  timeout        = 300
  lambda_trigger = false

  log_retention_in_days = local.lambda_log_retention_in_days

  env_vars = {
    "CLUSTER_ID"            = local.lambda_redshift_table_expiry_cluster_id
    "DB_NAME"               = local.lambda_redshift_table_expiry_database_name
    "CREDENTIAL_SECRET_ARN" = local.lambda_redshift_table_expiry_secret_arn
    "EXPIRY_SECONDS"        = local.lambda_redshift_table_expiry_seconds
  }

  tags = merge(
    local.all_tags,
    {
      Name           = local.lambda_redshift_table_expiry_name
      Jira           = "DPR2-991"
      Resource_Group = "Front-End"
      Resource_Type  = "lambda"
    }
  )

}

module "step_function_notification_lambda_trigger" {
  source = "./modules/lambda_trigger"

  enable_lambda_trigger = local.lambda_redshift_table_expiry_enabled

  event_name           = local.lambda_redshift_table_expiry_name
  lambda_function_arn  = module.redshift_table_expiry_lambda.lambda_function
  lambda_function_name = module.redshift_table_expiry_lambda.lambda_name

  trigger_schedule_expression = local.lambda_redshift_table_expiry_schedule_expression
}