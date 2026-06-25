module "lambda_custom_idp_layer" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.8.0"

  create_function = false
  create_layer    = true

  layer_name          = "${local.application_name}-${local.component_name}-custom-idp"
  description         = "Shared code for the AWS Transfer custom identity provider"
  compatible_runtimes = ["python3.12"]
  source_path         = "lambda/custom-idp/layer"

  trigger_on_package_timestamp = false

  tags = local.tags
}

module "lambda_custom_idp" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.8.0"

  function_name                  = "${local.application_name}-${local.component_name}-custom-idp"
  description                    = "Authenticates AWS Transfer users with DynamoDB metadata and Secrets Manager credentials"
  handler                        = "app.lambda_handler"
  layers                         = [module.lambda_custom_idp_layer.lambda_layer_arn]
  memory_size                    = 256
  reserved_concurrent_executions = 5
  runtime                        = "python3.12"
  source_path                    = "lambda/custom-idp/idp_handler"
  timeout                        = 30
  tracing_mode                   = "Active"
  trigger_on_package_timestamp   = false

  environment_variables = {
    IDENTITY_PROVIDERS_TABLE = module.dynamodb_custom_idp_identity_providers.dynamodb_table_id
    LOGLEVEL                 = local.custom_idp_configuration.log_level
    USER_NAME_DELIMITER      = local.custom_idp_configuration.user_name_delimiter
    USERS_TABLE              = module.dynamodb_custom_idp_users.dynamodb_table_id
  }

  attach_policy_statements = true
  policy_statements = {
    custom_idp_tables = {
      effect = "Allow"
      actions = [
        "dynamodb:GetItem",
        "dynamodb:Query",
      ]
      resources = [
        module.dynamodb_custom_idp_identity_providers.dynamodb_table_arn,
        module.dynamodb_custom_idp_users.dynamodb_table_arn,
      ]
    }
    custom_idp_secrets = {
      effect = "Allow"
      actions = [
        "secretsmanager:GetSecretValue",
      ]
      resources = [
        "arn:aws:secretsmanager:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:secret:${local.custom_idp_configuration.secret_prefix}*",
      ]
    }
    custom_idp_secrets_kms = {
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
      ]
      resources = [
        module.kms_secrets.key_arn,
      ]
    }
    describe_transfer_servers = {
      effect = "Allow"
      actions = [
        "transfer:DescribeServer",
      ]
      resources = [
        "arn:aws:transfer:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:server/*",
      ]
    }
  }

  attach_tracing_policy = true

  cloudwatch_logs_kms_key_id        = module.kms_cloudwatch_logs.key_arn
  cloudwatch_logs_retention_in_days = 30

  tags = local.tags
}

resource "aws_lambda_permission" "transfer_custom_idp" {
  action         = "lambda:InvokeFunction"
  function_name  = module.lambda_custom_idp.lambda_function_name
  principal      = "transfer.amazonaws.com"
  source_account = data.aws_caller_identity.current.account_id
  source_arn     = aws_transfer_server.this.arn
}
