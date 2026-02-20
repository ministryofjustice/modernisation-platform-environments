

# -------------------------------------------------
# 3. ZIP Archives (prod / non-prod)
# -------------------------------------------------
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda/authorizer.js"
  output_path = "lambda/authorizer.zip"
}


module "authorizer_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.5.0"

  function_name    = "hmac-authorizer"
  description      = "Custom TOKEN authorizer for API Gateway"
  source_path      = data.archive_file.lambda_zip.output_path
  handler          = "authorizer.handler"

  create_package         = false
  local_existing_package = data.archive_file.lambda_zip.output_path

  publish = true

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


resource "aws_lambda_permission" "apigw_authorizer" {
  statement_id  = "AllowAPIGatewayInvokeAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = module.authorizer_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.ingestion_api.execution_arn}/authorizers/*"
}


# IAM Role for API Gateway to push to SQS
module "lamdba_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.58.0"

  create_role       = true
  role_requires_mfa = false

  role_name = "lambda-sqs-role-mp"

  trusted_role_services = [
    "apigateway.amazonaws.com"
  ]
}


resource "aws_iam_role_policy" "lambda_policy" {
  role = module.lamdba_role.iam_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sqs:SendMessage"
        Resource = "arn:aws:sqs:eu-west-2:${data.aws_secretsmanager_secret_version.cloud_platform_account_id.secret_string}:${local.environment_configuration[local.environment].cloud_platform_sqs_queue_name}"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:GenerateDataKey",
          "kms:Decrypt"
        ]
        Resource = "*"
      }
    ]
  })
}
