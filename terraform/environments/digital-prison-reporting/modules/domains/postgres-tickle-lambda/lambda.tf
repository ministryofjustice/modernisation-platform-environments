# Lambda which is designed to ensure Postgres replication slots keep moving when there is no activity to read from that slot
module "postgres_tickle_lambda" {
  source = "../../lambdas/generic"

  enable_lambda = var.setup_postgres_tickle_lambda
  name          = var.postgres_tickle_lambda_name
  s3_bucket     = var.lambda_code_s3_bucket
  s3_key        = var.lambda_code_s3_key
  handler       = var.lambda_handler
  runtime       = var.lambda_runtime
  policies      = var.lambda_policies
  tracing       = var.lambda_tracing
  timeout       = var.lambda_timeout_in_seconds
  memory_size   = var.memory_size
  env_vars      = var.env_vars
  secret_arns   = var.secret_arns

  log_retention_in_days = var.lambda_log_retention_in_days

  vpc_settings = {
    subnet_ids         = var.lambda_subnet_ids
    security_group_ids = var.lambda_security_group_ids
  }

  tags = merge(
    var.tags,
    {
      Resource_Type = "Lambda"
      Name          = var.postgres_tickle_lambda_name
    }
  )
}
