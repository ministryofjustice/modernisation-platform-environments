module "lambda_custom_idp_layer" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.8.0"

  architectures   = ["arm64"]
  create_function = false
  create_layer    = true

  layer_name          = "${local.application_name}-custom-idp"
  description         = "Shared code for the AWS Transfer custom identity provider"
  compatible_runtimes = ["python3.12"]
  source_path         = "lambda/custom-idp/layer"

  trigger_on_package_timestamp = false

  tags = local.tags
}

module "lambda_custom_idp" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.8.0"

  function_name                  = "${local.application_name}-custom-idp"
  architectures                  = ["arm64"]
  description                    = "Authenticates AWS Transfer users with Secrets Manager"
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
    LOGLEVEL                = local.custom_idp_configuration.log_level
    SECRET_PREFIX           = local.custom_idp_configuration.secret_prefix
    AWS_ACCOUNT_ID          = data.aws_caller_identity.current.account_id
    TRANSFER_ROLE_ARN       = module.iam_role_transfer_user.arn
    TRANSFER_SESSION_POLICY = data.aws_iam_policy_document.transfer_user_session.json
    TRANSFER_HOME_DIRECTORY_DETAILS = jsonencode([{
      Entry  = "/"
      Target = "/${module.s3_bucket["incoming"].s3_bucket_id}/{{USERNAME}}"
    }])
  }

  attach_policy_statements = true
  policy_statements = {
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
  }

  attach_tracing_policy = true

  cloudwatch_logs_kms_key_id        = module.kms_cloudwatch_logs.key_arn
  cloudwatch_logs_retention_in_days = local.cloudwatch_retention_days

  tags = local.tags
}

resource "aws_lambda_permission" "transfer_custom_idp" {
  action         = "lambda:InvokeFunction"
  function_name  = module.lambda_custom_idp.lambda_function_name
  principal      = "transfer.amazonaws.com"
  source_account = data.aws_caller_identity.current.account_id
  source_arn     = aws_transfer_server.this.arn
}
