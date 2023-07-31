data "aws_iam_policy_document" "iam_policy_document_for_docs_lambda" {
  statement {
    sid       = "LambdaLogGroup"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/*"]
  }
}

module "data_product_docs_lambda" {
  source                         = "github.com/ministryofjustice/modernisation-platform-terraform-lambda-function?ref=v2.0.1"
  application_name               = "data_product_docs"
  tags                           = local.tags
  description                    = "Lambda for swagger api docs"
  function_name                  = "data_product_docs_${local.environment}"
  role_name                      = "docs_lambda_role_${local.environment}"
  policy_json                    = data.aws_iam_policy_document.iam_policy_document_for_docs_lambda.json
  create_role                    = true
  reserved_concurrent_executions = 1

  image_uri    = "374269020027.dkr.ecr.eu-west-2.amazonaws.com/data-platform-docs-lambda-ecr-repo:1.0.1"
  timeout      = 600
  tracing_mode = "Active"
  memory_size  = 512

  allowed_triggers = {

    AllowExecutionFromAPIGateway = {
      action        = "lambda:InvokeFunction"
      function_name = "data_product_docs_${local.environment}"
      principal     = "apigateway.amazonaws.com"
      source_arn    = "arn:aws:execute-api:${local.region}:${local.account_id}:${aws_api_gateway_rest_api.data_platform.id}/*/*"
    }
  }

}

resource "aws_api_gateway_resource" "docs" {
  rest_api_id = aws_api_gateway_rest_api.data_platform.id
  parent_id   = aws_api_gateway_rest_api.data_platform.root_resource_id
  path_part   = "docs"
}

resource "aws_api_gateway_method" "docs" {
  rest_api_id   = aws_api_gateway_rest_api.data_platform.id
  resource_id   = aws_api_gateway_resource.docs.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "docs_to_lambda" {
  rest_api_id = aws_api_gateway_rest_api.data_platform.id
  resource_id = aws_api_gateway_method.docs.resource_id
  http_method = aws_api_gateway_method.docs.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.data_product_docs_lambda.lambda_function_invoke_arn
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.data_platform.id
  parent_id   = aws_api_gateway_resource.docs.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.data_platform.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "proxy_to_lambda" {
  rest_api_id = aws_api_gateway_rest_api.data_platform.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.data_product_docs_lambda.lambda_function_invoke_arn
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.data_platform.id
  resource_id   = aws_api_gateway_rest_api.data_platform.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "docs_lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.data_platform.id
  resource_id = aws_api_gateway_method.proxy_root.resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method

  integration_http_method = "POST"
  type                    = "MOCK"
  uri                     = module.data_product_docs_lambda.lambda_function_invoke_arn

  lifecycle {
    ignore_changes = all
  }
}

output "docs_endpoint" {
  value = join("", [aws_api_gateway_deployment.deployment.invoke_url, aws_api_gateway_stage.sandbox.stage_name, "/docs/"])
}
