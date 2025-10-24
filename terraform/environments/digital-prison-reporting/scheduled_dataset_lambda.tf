module "scheduled_dataset_lambda" {
  source = "./modules/lambdas/generic"

  enable_lambda  = local.lambda_scheduled_dataset_enabled
  name           = local.lambda_scheduled_dataset_name
  s3_bucket      = local.lambda_scheduled_dataset_code_s3_bucket
  s3_key         = local.lambda_scheduled_dataset_code_s3_key
  handler        = local.lambda_scheduled_dataset_handler
  runtime        = local.lambda_scheduled_dataset_runtime
  policies       = local.lambda_scheduled_dataset_policies
  tracing        = local.lambda_scheduled_dataset_tracing
  timeout        = local.lambda_scheduled_dataset_timeout_seconds
  memory_size    = local.lambda_scheduled_dataset_memory_size
  lambda_trigger = false

  log_retention_in_days = local.lambda_log_retention_in_days

  env_vars = {
    "CLUSTER_ID"            = local.lambda_scheduled_dataset_cluster_id
    "DB_NAME"               = local.lambda_scheduled_dataset_database_name
    "CREDENTIAL_SECRET_ARN" = local.lambda_scheduled_dataset_secret_arn
    "DPD_DDB_TABLE_ARN"     = local.lambda_scheduled_dataset_dpd_ddb_table_arn
  }

  vpc_settings = {
    subnet_ids         = [data.aws_subnet.data_subnets_a.id, data.aws_subnet.data_subnets_b.id, data.aws_subnet.data_subnets_c.id]
    security_group_ids = [aws_security_group.lambda_generic[0].id]
  }

  tags = merge(
    local.all_tags,
    {
      dpr-name           = local.lambda_scheduled_dataset_name
      dpr-jira           = "DPR2-1513"
      dpr-resource-group = "Front-End"
      dpr-resource-type  = "lambda"
    }
  )

}

module "scheduled_dataset_lambda_trigger" {
  source = "./modules/lambda_trigger"

  enable_lambda_trigger = local.lambda_scheduled_dataset_enabled

  event_name           = local.lambda_scheduled_dataset_name
  lambda_function_arn  = module.scheduled_dataset_lambda.lambda_function
  lambda_function_name = module.scheduled_dataset_lambda.lambda_name

  trigger_schedule_expression = local.lambda_scheduled_dataset_schedule_expression
}