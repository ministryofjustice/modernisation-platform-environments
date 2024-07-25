# Domain Builder Flyway Lambda

locals {
  transfer_component_migrations_repo = "https://github.com/ministryofjustice/digital-prison-reporting-transfer-component"
}

module "transfer_comp_lambda_layer" {
  source = "./modules/lambdas/layer"

  create_layer        = local.create_transfercomp_lambda_layer
  layer_name          = local.lambda_transfercomp_layer_name
  description         = "Redshift JDBC Depedency Jar for Flyway Lambda"
  license_info        = "HMPPS, MOJ Reporting Team"
  local_file          = "transfer-component/redshift_dependency.zip"
  compatible_runtimes = ["java11"]
}

module "transfer_comp_Lambda" {
  source = "./modules/lambdas/generic"

  enable_lambda  = local.enable_transfercomp_lambda
  name           = local.lambda_transfercomp_name
  s3_bucket      = local.lambda_transfercomp_code_s3_bucket
  s3_key         = local.lambda_transfercomp_code_s3_key
  handler        = local.lambda_transfercomp_handler
  runtime        = local.lambda_transfercomp_runtime
  policies       = local.lambda_transfercomp_policies
  tracing        = local.lambda_transfercomp_tracing
  timeout        = 300
  lambda_trigger = false
  layers         = [module.transfer_comp_lambda_layer.lambda_layer_arn, ]

  log_retention_in_days = local.lambda_log_retention_in_days

  env_vars = {
    "DB_CONNECTION_STRING" = "placeholder"
    "DB_USERNAME"          = "placeholder"
    "DB_PASSWORD"          = "placeholder"
    "FLYWAY_METHOD"        = "check"
    "GIT_FOLDERS"          = "placeholder" # Comma Seperated List
    "GIT_REPOSITORY"       = local.transfer_component_migrations_repo
  }

  vpc_settings = {
    subnet_ids         = [data.aws_subnet.data_subnets_a.id, data.aws_subnet.data_subnets_b.id, data.aws_subnet.data_subnets_c.id]
    security_group_ids = [aws_security_group.lambda_generic[0].id, ]
  }

  tags = merge(
    local.all_tags,
    {
      Name           = local.lambda_transfercomp_name
      Jira           = "DPR-504"
      Resource_Group = "transfer-component"
      Resource_Type  = "lambda"
    }
  )

}
