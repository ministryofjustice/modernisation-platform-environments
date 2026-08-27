resource "aws_cloudwatch_log_group" "api_access" {
  count = local.create_service ? 1 : 0

  name              = "/aws/apigateway/${local.application_name}-${local.component_name}"
  kms_key_id        = module.kms_cloudwatch_logs[0].key_arn
  retention_in_days = 365
  tags              = local.tags
}

resource "aws_apigatewayv2_api" "benefit_checker" {
  count = local.create_service ? 1 : 0

  name          = "${local.application_name}-${local.component_name}"
  protocol_type = "HTTP"
  dynamic "cors_configuration" {
    for_each = length(local.cors_allowed_origins) > 0 ? [1] : []
    content {
      allow_headers  = ["authorization", "content-type", "x-correlation-id"]
      allow_methods  = ["GET", "OPTIONS", "POST"]
      allow_origins  = local.cors_allowed_origins
      expose_headers = ["content-type", "x-correlation-id"]
      max_age        = 300
    }
  }
  tags = local.tags
}

resource "aws_apigatewayv2_integration" "benefit_orchestrator" {
  count = local.create_service ? 1 : 0

  api_id                 = aws_apigatewayv2_api.benefit_checker[0].id
  integration_type       = "AWS_PROXY"
  integration_uri        = module.lambda_benefit_orchestrator[0].lambda_function_invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
  timeout_milliseconds   = 10000
}

resource "aws_apigatewayv2_authorizer" "request" {
  count = local.create_service ? 1 : 0

  api_id                            = aws_apigatewayv2_api.benefit_checker[0].id
  authorizer_type                   = "REQUEST"
  name                              = "${local.application_name}-${local.component_name}-authorizer"
  authorizer_uri                    = module.lambda_api_authorizer[0].lambda_function_invoke_arn
  authorizer_payload_format_version = "2.0"
  authorizer_result_ttl_in_seconds  = 0
  enable_simple_responses           = true
  identity_sources                  = ["$request.header.Authorization"]
}

resource "aws_apigatewayv2_route" "assessment" {
  count = local.create_service ? 1 : 0

  api_id             = aws_apigatewayv2_api.benefit_checker[0].id
  route_key          = "POST /v1/benefit-checks/assessments"
  target             = "integrations/${aws_apigatewayv2_integration.benefit_orchestrator[0].id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.request[0].id
}

resource "aws_apigatewayv2_route" "health" {
  #checkov:skip=CKV_AWS_309:The health endpoint is intentionally public and returns no sensitive data
  count = local.create_service ? 1 : 0

  api_id             = aws_apigatewayv2_api.benefit_checker[0].id
  route_key          = "GET /health"
  target             = "integrations/${aws_apigatewayv2_integration.benefit_orchestrator[0].id}"
  authorization_type = "NONE"
}

resource "aws_apigatewayv2_stage" "default" {
  count = local.create_service ? 1 : 0

  api_id      = aws_apigatewayv2_api.benefit_checker[0].id
  name        = "$default"
  auto_deploy = true
  default_route_settings {
    throttling_burst_limit = local.burst_limit
    throttling_rate_limit  = local.rate_limit
  }
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_access[0].arn
    format = jsonencode({
      requestId      = "$context.requestId"
      sourceIp       = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      responseLength = "$context.responseLength"
    })
  }
  tags = local.tags
}

resource "aws_lambda_permission" "api_gateway_orchestrator" {
  count = local.create_service ? 1 : 0

  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_benefit_orchestrator[0].lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.benefit_checker[0].execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gateway_authorizer" {
  count = local.create_service ? 1 : 0

  statement_id  = "AllowExecutionFromApiGatewayAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_api_authorizer[0].lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.benefit_checker[0].execution_arn}/authorizers/${aws_apigatewayv2_authorizer.request[0].id}"
}
