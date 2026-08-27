data "aws_secretsmanager_secret" "downstream_basic_auth" {
  count = local.create_service ? 1 : 0
  name  = local.downstream_basic_auth_secret_id
}

module "lambda_benefit_orchestrator" {
  count = local.create_service ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-lambda.git?ref=b842374147fc07731d79028517223e9e0cbaab6d" # v8.8.0

  function_name                = "${local.application_name}-${local.component_name}-benefit-orchestrator"
  description                  = "Orchestrates requests to the downstream mock benefit checker"
  handler                      = "lambda_function.lambda_handler"
  runtime                      = "python3.13"
  timeout                      = 15
  memory_size                  = 256
  source_path                  = "${local.bootstrap_code_root}/benefit-orchestrator"
  trigger_on_package_timestamp = false
  environment_variables = {
    DOWNSTREAM_BENEFIT_CHECKER_URL  = local.downstream_benefit_checker_url
    DOWNSTREAM_BASIC_AUTH_SECRET_ID = data.aws_secretsmanager_secret.downstream_basic_auth[0].name
    DOWNSTREAM_TIMEOUT_SECONDS      = "5"
    SECRET_CACHE_TTL_SECONDS        = "300"
  }
  attach_policy_statements = true
  policy_statements = {
    downstream_secret_read = {
      effect    = "Allow"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = [data.aws_secretsmanager_secret.downstream_basic_auth[0].arn]
    }
  }
  cloudwatch_logs_retention_in_days = 30
  tags                              = local.tags
}

module "lambda_api_authorizer" {
  count = local.create_service ? 1 : 0

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-lambda.git?ref=b842374147fc07731d79028517223e9e0cbaab6d" # v8.8.0

  function_name                = "${local.application_name}-${local.component_name}-authorizer"
  description                  = "Authenticates benefit checker API clients"
  handler                      = "lambda_function.lambda_handler"
  runtime                      = "python3.13"
  source_path                  = "${local.bootstrap_code_root}/request-authorizer"
  trigger_on_package_timestamp = false
  environment_variables = {
    AUTH_PRINCIPALS_TABLE = module.dynamodb_auth_principals[0].dynamodb_table_id
    AUTH_ROLES_TABLE      = module.dynamodb_auth_roles[0].dynamodb_table_id
  }
  attach_policy_statements = true
  policy_statements = {
    auth_tables_read = {
      effect  = "Allow"
      actions = ["dynamodb:GetItem"]
      resources = [
        module.dynamodb_auth_principals[0].dynamodb_table_arn,
        module.dynamodb_auth_roles[0].dynamodb_table_arn,
      ]
    }
    auth_secrets_read = {
      effect  = "Allow"
      actions = ["secretsmanager:GetSecretValue"]
      resources = concat(
        [for secret in values(module.api_user_credentials_secret) : secret.secret_arn],
        [for secret in values(module.api_system_bearer_token_secret) : secret.secret_arn],
      )
    }
  }
  cloudwatch_logs_retention_in_days = 30
  tags                              = local.tags
}
