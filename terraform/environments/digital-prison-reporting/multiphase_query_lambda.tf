module "multiphase_query_lambda" {
  source = "./modules/lambdas/generic"

  enable_lambda  = local.lambda_multiphase_query_enabled
  name           = local.lambda_multiphase_query_name
  s3_bucket      = local.lambda_multiphase_query_code_s3_bucket
  s3_key         = local.lambda_multiphase_query_code_s3_key
  handler        = local.lambda_multiphase_query_handler
  runtime        = local.lambda_multiphase_query_runtime
  policies       = local.lambda_multiphase_query_policies
  tracing        = local.lambda_multiphase_query_tracing
  timeout        = local.lambda_multiphase_query_timeout_seconds
  memory_size    = local.lambda_multiphase_query_memory_size
  lambda_trigger = false

  log_retention_in_days = local.lambda_log_retention_in_days

  env_vars = {
    "CLUSTER_ID"            = local.lambda_multiphase_query_cluster_id
    "DB_NAME"               = local.lambda_multiphase_query_database_name
    "CREDENTIAL_SECRET_ARN" = local.lambda_multiphase_query_secret_arn
  }

  vpc_settings = {
    subnet_ids         = [data.aws_subnet.data_subnets_a.id, data.aws_subnet.data_subnets_b.id, data.aws_subnet.data_subnets_c.id]
    security_group_ids = [aws_security_group.lambda_generic[0].id]
  }

  tags = merge(
    local.all_tags,
    {
      dpr-name           = local.lambda_multiphase_query_name
      dpr-jira           = "DPR2-1906"
      dpr-resource-group = "Front-End"
      dpr-resource-type  = "lambda"
    }
  )
}

module "multiphase_query_lambda_trigger" {
  source = "./modules/lambda_trigger"

  enable_lambda_trigger = local.lambda_multiphase_query_enabled

  event_name           = local.lambda_multiphase_query_name
  event_bus_name       = local.default_event_bus
  lambda_function_arn  = module.multiphase_query_lambda.lambda_function
  lambda_function_name = module.multiphase_query_lambda.lambda_name

  trigger_event_pattern = jsonencode(
    {
      "source" : ["aws.athena"],
      "detail-type" : ["Athena Query State Change"],
      "detail" : {
        "workgroupName" : ["dpr-generic-athena-workgroup"]
      }
    }
  )
}
