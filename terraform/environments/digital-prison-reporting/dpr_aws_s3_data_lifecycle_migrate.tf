# Domain Builder Backend Lambda function
module "aws_s3_data_migrate" {
  source = "./modules/lambdas/generic"

  enable_lambda = local.enable_s3_data_migrate_lambda
  name          = local.lambda_s3_data_migrate_name
  s3_bucket     = local.lambda_s3_data_migrate_code_s3_bucket
  s3_key        = local.lambda_s3_data_migrate_code_s3_key
  handler       = local.lambda_s3_data_migrate_handler
  runtime       = local.lambda_s3_data_migrate_runtime
  policies      = local.lambda_s3_data_migrate_policies
  tracing       = local.lambda_s3_data_migrate_tracing

  log_retention_in_days = local.lambda_log_retention_in_days

  # Set timeout to the maximum of 900 seconds (15 minutes)
  timeout = 900

  # Optional: Adjust memory size if needed
  memory_size = 2048

  vpc_settings = {
    subnet_ids         = [data.aws_subnet.data_subnets_a.id, data.aws_subnet.data_subnets_b.id, data.aws_subnet.data_subnets_c.id]
    security_group_ids = [aws_security_group.lambda_generic[0].id, ]
  }

  tags = merge(
    local.all_tags,
    {
      dpr-resource-group = "dpr-operations"
      dpr-jira           = "DPR2-1368"
      dpr-resource-type  = "lambda"
      dpr-name           = local.lambda_s3_data_migrate_name
    }
  )

  depends_on = [aws_iam_policy.s3_read_access_policy, aws_iam_policy.s3_read_write_policy, aws_iam_policy.kms_read_access_policy]
}