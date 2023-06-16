data "archive_file" "docs_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src/docs"
  output_path = "${path.module}/src/docs_${local.environment}/docs_lambda.zip"
}

resource "aws_lambda_function" "api_docs" {
  function_name = "api_docs"

  filename = "${path.module}/src/docs_${local.environment}/docs_lambda.zip"
  source_code_hash = data.archive_file.docs_zip.output_base64sha256
  handler = "main.handler"
  runtime = "nodejs14.x"

  role = aws_iam_role.api_docs_lambda_role.arn
}

resource "aws_iam_role" "api_docs_lambda_role" {
  name               = "serverless_example_lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "attach_policy_to_lambda_role" {
  role       = aws_iam_role.api_docs_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_api_gateway_resource" "docs" {
  rest_api_id = aws_api_gateway_rest_api.data_platform.id
  parent_id   = aws_api_gateway_rest_api.data_platform.root_resource_id
  path_part   = "docs"
}

resource "aws_api_gateway_method" "docs_root" {
  rest_api_id   = aws_api_gateway_rest_api.data_platform.id
  resource_id   = aws_api_gateway_resource.docs.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_docs_root" {
  rest_api_id = aws_api_gateway_rest_api.data_platform.id
  resource_id = aws_api_gateway_method.docs_root.resource_id
  http_method = aws_api_gateway_method.docs_root.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_docs.invoke_arn
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

resource "aws_api_gateway_integration" "docs_lambda" {
  rest_api_id = aws_api_gateway_rest_api.data_platform.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_docs.invoke_arn
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
  uri                     = aws_lambda_function.api_docs.invoke_arn

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_lambda_permission" "allow_apigw_to_invoke_docs_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_docs.function_name
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.data_platform.execution_arn}/*/*"
}

output "go_to" {
  value = join("", [aws_api_gateway_deployment.deployment.invoke_url, "/docs/"])
}
