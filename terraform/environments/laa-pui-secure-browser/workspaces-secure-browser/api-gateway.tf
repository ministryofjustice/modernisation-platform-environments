####################
# API Gateway HTTP API for OAuth callback
####################
resource "aws_apigatewayv2_api" "callback" {
  count = local.create_resources ? 1 : 0

  name          = "${local.application_name}-callback-api-${local.environment}"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["https://login.microsoftonline.com"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["*"]
    max_age       = 300
  }

  tags = merge(
    local.tags,
    {
      Name = "callback-api"
    }
  )
}

# JWT Authorizer for API Gateway
resource "aws_apigatewayv2_authorizer" "jwt" {
  count = local.create_resources ? 1 : 0

  api_id           = aws_apigatewayv2_api.callback[0].id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "entra-jwt-authorizer"

  jwt_configuration {
    audience = [local.azure_config.client_id]
    issuer   = "https://login.microsoftonline.com/${local.azure_config.tenant_id}/v2.0"
  }
}

resource "aws_apigatewayv2_integration" "callback_lambda" {
  count = local.create_resources ? 1 : 0

  api_id                 = aws_apigatewayv2_api.callback[0].id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.callback[0].invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "callback" {
  count = local.create_resources ? 1 : 0

  api_id             = aws_apigatewayv2_api.callback[0].id
  route_key          = "GET /callback"
  target             = "integrations/${aws_apigatewayv2_integration.callback_lambda[0].id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt[0].id
}

resource "aws_apigatewayv2_stage" "callback_default" {
  count = local.create_resources ? 1 : 0

  api_id      = aws_apigatewayv2_api.callback[0].id
  name        = "$default"
  auto_deploy = true

  tags = merge(
    local.tags,
    {
      Name = "callback-api-stage"
    }
  )
}

resource "aws_lambda_permission" "allow_apigw" {
  count = local.create_resources ? 1 : 0

  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.callback[0].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.callback[0].execution_arn}/*/*"
}
