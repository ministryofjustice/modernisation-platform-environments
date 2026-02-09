module "authorizer_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.5.0"

  function_name = "hmac-authorizer"
  description   = "Custom TOKEN authorizer for API Gateway"
  handler       = "authorizer.handler"
  runtime       = "nodejs18.x"

  create_package         = false
  local_existing_package = data.archive_file.authorizer.output_path

  environment_variables = {
    SECRET_ID = module.secret_ingestion_api_auth_token.secret_arn
  }

  attach_policy_statements = true
  policy_statements = {
    secrets = {
      effect    = "Allow"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = [module.secret_ingestion_api_auth_token.secret_arn]
    }
    kms = {
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
      resources = [module.secrets_kms.key_arn]
    }
  }

  # IAM Roles & Policies
  create_role = true
  role_name   = "authorizer-role-mp"

  tags = local.tags
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.authorizer_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.ingestion_api.execution_arn}/*/*/*"
}


