module "generate_dataset_lambda" {
  source = "./modules/lambdas/generic"

  enable_lambda  = local.lambda_generate_dataset_enabled
  name           = local.lambda_generate_dataset_name
  s3_bucket      = local.lambda_generate_dataset_code_s3_bucket
  s3_key         = local.lambda_generate_dataset_code_s3_key
  handler        = local.lambda_generate_dataset_handler
  runtime        = local.lambda_generate_dataset_runtime
  policies       = local.lambda_generate_dataset_policies
  tracing        = local.lambda_generate_dataset_tracing
  timeout        = local.lambda_generate_dataset_timeout_seconds
  memory_size    = local.lambda_generate_dataset_memory_size
  lambda_trigger = false

  log_retention_in_days = local.lambda_log_retention_in_days

  env_vars = {
    "CLUSTER_ID"            = local.lambda_generate_dataset_cluster_id
    "DB_NAME"               = local.lambda_generate_dataset_database_name
    "CREDENTIAL_SECRET_ARN" = local.lambda_generate_dataset_secret_arn
    "DPD_DDB_TABLE_ARN"     = local.lambda_generate_dataset_dpd_ddb_table_arn
  }

  vpc_settings = {
    subnet_ids         = [data.aws_subnet.data_subnets_a.id, data.aws_subnet.data_subnets_b.id, data.aws_subnet.data_subnets_c.id]
    security_group_ids = [aws_security_group.lambda_generic[0].id]
  }

  tags = merge(
    local.all_tags,
    {
      Name           = local.lambda_generate_dataset_name
      Jira           = "DPR2-1715"
      Resource_Group = "Front-End"
      Resource_Type  = "lambda"
    }
  )

}

module "generate_dataset_lambda_trigger" {
  source = "./modules/lambda_trigger"

  enable_lambda_trigger = local.lambda_generate_dataset_enabled

  event_name           = local.lambda_generate_dataset_name
  event_bus_name       = local.event_bus_dpr
  lambda_function_arn  = module.generate_dataset_lambda.lambda_function
  lambda_function_name = module.generate_dataset_lambda.lambda_name

  trigger_event_pattern = jsonencode(
    {
      "source" : ["uk.gov.justice.digital.hmpps.scheduled.lambda.ReportSchedulerLambda"],
      "detail-type" : ["RedshiftDatasetGenerate"]
    }
  )
}