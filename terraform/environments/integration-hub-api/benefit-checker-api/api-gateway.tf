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

  api_id           = aws_apigatewayv2_api.benefit_checker[0].id
  authorizer_type  = "JWT"
  name             = "${local.application_name}-${local.component_name}-entra"
  identity_sources = ["$request.header.Authorization"]
  jwt_configuration {
    audience = [local.entra_api_audience]
    issuer   = "https://login.microsoftonline.com/${local.entra_tenant_id}/v2.0"
  }
  lifecycle {
    precondition {
      condition = (
        can(regex("^[0-9a-fA-F-]{36}$", local.entra_tenant_id)) &&
        can(regex("^[0-9a-fA-F-]{36}$", local.entra_api_audience)) &&
        length(local.entra_allowed_client_ids) > 0 &&
        alltrue([for id in local.entra_allowed_client_ids : can(regex("^[0-9a-fA-F-]{36}$", id))])
      )
      error_message = "Configure the dedicated pilot Entra tenant, API client ID and approved consumer client IDs before applying."
    }
  }
}

resource "aws_apigatewayv2_route" "assessment" {
  count = local.create_service ? 1 : 0

  api_id             = aws_apigatewayv2_api.benefit_checker[0].id
  route_key          = "POST /v1/benefit-checks/assessments"
  target             = "integrations/${aws_apigatewayv2_integration.benefit_orchestrator[0].id}"
  authorization_type = "JWT"
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
