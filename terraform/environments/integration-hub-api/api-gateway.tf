resource "aws_cloudwatch_log_group" "api_access" {
  name              = "/aws/apigateway/${local.resource_name_prefix}"
  kms_key_id        = module.kms_cloudwatch_logs.key_arn
  retention_in_days = 30
  tags              = local.tags
}

resource "aws_apigatewayv2_api" "upload_ticket" {
  name          = local.resource_name_prefix
  protocol_type = "HTTP"

  dynamic "cors_configuration" {
    for_each = length(local.cors_allowed_origins) > 0 ? [1] : []

    content {
      allow_headers = ["authorization", "content-md5", "content-type"]
      allow_methods = ["DELETE", "OPTIONS", "POST"]
      allow_origins = local.cors_allowed_origins
      expose_headers = [
        "content-type",
      ]
      max_age = 300
    }
  }

  tags = local.tags
}

resource "aws_apigatewayv2_integration" "upload_ticket" {
  api_id                 = aws_apigatewayv2_api.upload_ticket.id
  integration_type       = "AWS_PROXY"
  integration_uri        = module.lambda_upload_ticket.lambda_function_invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "api_docs" {
  api_id                 = aws_apigatewayv2_api.upload_ticket.id
  integration_type       = "AWS_PROXY"
  integration_uri        = module.lambda_api_docs.lambda_function_invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_authorizer" "mft_request" {
  api_id                            = aws_apigatewayv2_api.upload_ticket.id
  authorizer_type                   = "REQUEST"
  name                              = "${local.resource_name_prefix}-authorizer"
  authorizer_uri                    = module.lambda_api_authorizer.lambda_function_invoke_arn
  authorizer_payload_format_version = "2.0"
  enable_simple_responses           = true
  identity_sources                  = ["$request.header.Authorization"]
}

resource "aws_apigatewayv2_route" "transfer_tickets" {
  api_id             = aws_apigatewayv2_api.upload_ticket.id
  route_key          = "POST /transfer-tickets"
  target             = "integrations/${aws_apigatewayv2_integration.upload_ticket.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.mft_request.id
}

resource "aws_apigatewayv2_route" "transfer_ticket_parts" {
  api_id             = aws_apigatewayv2_api.upload_ticket.id
  route_key          = "POST /transfer-tickets/{transferTicket}/parts"
  target             = "integrations/${aws_apigatewayv2_integration.upload_ticket.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.mft_request.id
}

resource "aws_apigatewayv2_route" "transfer_ticket_complete" {
  api_id             = aws_apigatewayv2_api.upload_ticket.id
  route_key          = "POST /transfer-tickets/{transferTicket}/complete"
  target             = "integrations/${aws_apigatewayv2_integration.upload_ticket.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.mft_request.id
}

resource "aws_apigatewayv2_route" "transfer_ticket_abort" {
  api_id             = aws_apigatewayv2_api.upload_ticket.id
  route_key          = "DELETE /transfer-tickets/{transferTicket}"
  target             = "integrations/${aws_apigatewayv2_integration.upload_ticket.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.mft_request.id
}

resource "aws_apigatewayv2_route" "api_docs" {
  api_id    = aws_apigatewayv2_api.upload_ticket.id
  route_key = "GET /docs"
  target    = "integrations/${aws_apigatewayv2_integration.api_docs.id}"
}

resource "aws_apigatewayv2_route" "api_openapi_contract" {
  api_id    = aws_apigatewayv2_api.upload_ticket.id
  route_key = "GET /openapi.yaml"
  target    = "integrations/${aws_apigatewayv2_integration.api_docs.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.upload_ticket.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    detailed_metrics_enabled = true
    throttling_burst_limit   = local.api_gateway_throttling_configuration.burst_limit
    throttling_rate_limit    = local.api_gateway_throttling_configuration.rate_limit
  }
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_access.arn
    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      httpMethod              = "$context.httpMethod"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      protocol                = "$context.protocol"
      responseLength          = "$context.responseLength"
      responseLatency         = "$context.responseLatency"
      integrationStatus       = "$context.integration.status"
      integrationLatency      = "$context.integration.latency"
      integrationErrorMessage = "$context.integrationErrorMessage"
      authorizerError         = "$context.authorizer.error"
    })
  }

  tags = local.tags
}

resource "aws_lambda_permission" "allow_api_gateway_upload_ticket" {
  statement_id  = "AllowExecutionFromApiGatewayUploadTicket"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_upload_ticket.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.upload_ticket.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_api_gateway_authorizer" {
  statement_id  = "AllowExecutionFromApiGatewayAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_api_authorizer.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.upload_ticket.execution_arn}/authorizers/${aws_apigatewayv2_authorizer.mft_request.id}"
}

resource "aws_lambda_permission" "allow_api_gateway_api_docs" {
  statement_id  = "AllowExecutionFromApiGatewayApiDocs"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_api_docs.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.upload_ticket.execution_arn}/*/*"
}
