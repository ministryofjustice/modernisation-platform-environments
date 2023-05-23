resource "aws_apigatewayv2_api" "data_platform" {
  name          = "data_platform"
  protocol_type = "HTTP"
  tags = local.tags
}

resource "aws_apigatewayv2_stage" "api_gateway_stage" {
  api_id = aws_apigatewayv2_api.data_platform.id

  name        = local.environment
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

resource "aws_apigatewayv2_integration" "presigned_url" {
  api_id = aws_apigatewayv2_api.data_platform.id

  integration_uri    = aws_lambda_function.presigned_url.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "GET"
}

resource "aws_apigatewayv2_route" "presigned_url" {
  api_id = aws_apigatewayv2_api.data_platform.id

  route_key = "GET /upload_data"
  target    = "integrations/${aws_apigatewayv2_integration.presigned_url.id}"
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.data_platform.name}"

  retention_in_days = 30
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.presigned_url.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.data_platform.execution_arn}/*/*"
}

resource "aws_api_gateway_authorizer" "authorizer" {
  name                   = "authorizer-${local.environment}"
  rest_api_id            = aws_apigatewayv2_api.data_platform.id
  authorizer_uri         = aws_lambda_function.authoriser.invoke_arn
  authorizer_credentials = aws_iam_role.authoriser_lambda_role.arn
}
