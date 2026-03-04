
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda/authorizer.js"
  output_path = "lambda/authorizer.zip"
}

module "authorizer_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.5.0"

  function_name = "hmac-authorizer"
  description   = "Custom HMAC authorizer and method handler for API Gateway"
  handler       = "authorizer.handler"
  runtime       = "nodejs20.x"

  create_package         = false
  local_existing_package = data.archive_file.lambda_zip.output_path

  publish = true

  environment_variables = {
    SECRET_ID = module.secret_ingestion_api_auth_token.secret_arn
    SQS_URL   = "https://sqs.eu-west-2.amazonaws.com/${data.aws_secretsmanager_secret_version.cloud_platform_account_id.secret_string}/${local.environment_configuration[local.environment].cloud_platform_sqs_queue_name}"
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
      actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
      resources = ["*"]
    }
    sqs = {
      effect    = "Allow"
      actions   = ["sqs:sendmessage"]
      resources = ["arn:aws:sqs:eu-west-2:${data.aws_secretsmanager_secret_version.cloud_platform_account_id.secret_string}:${local.environment_configuration[local.environment].cloud_platform_sqs_queue_name}"]
    }
  }

  # IAM Roles & Policies
  create_role = true
  role_name   = "authorizer-role-mp"


  tags = local.tags
}


resource "aws_lambda_permission" "apigw_authorizer" {
  statement_id  = "AllowAPIGatewayInvokeAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = module.authorizer_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.ingestion_api.execution_arn}/${aws_api_gateway_method.post.http_method}${aws_api_gateway_resource.ingest.path}"
}