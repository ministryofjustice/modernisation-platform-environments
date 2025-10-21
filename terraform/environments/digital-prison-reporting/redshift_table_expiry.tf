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
  timeout        = local.lambda_redshift_table_expiry_timeout_seconds
  memory_size    = local.lambda_redshift_table_expiry_memory_size
  lambda_trigger = false

  log_retention_in_days = local.lambda_log_retention_in_days

  env_vars = {
    "CLUSTER_ID"            = local.lambda_redshift_table_expiry_cluster_id
    "DB_NAME"               = local.lambda_redshift_table_expiry_database_name
    "CREDENTIAL_SECRET_ARN" = local.lambda_redshift_table_expiry_secret_arn
    "EXPIRY_SECONDS"        = local.lambda_redshift_table_expiry_seconds
  }

  vpc_settings = {
    subnet_ids         = [data.aws_subnet.data_subnets_a.id, data.aws_subnet.data_subnets_b.id, data.aws_subnet.data_subnets_c.id]
    security_group_ids = [aws_security_group.lambda_generic[0].id]
  }

  tags = merge(
    local.all_tags,
    {
      dpr-name           = local.lambda_redshift_table_expiry_name
      dpr-jira           = "DPR2-991"
      dpr-resource-group = "Front-End"
      dpr-resource-type  = "lambda"
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