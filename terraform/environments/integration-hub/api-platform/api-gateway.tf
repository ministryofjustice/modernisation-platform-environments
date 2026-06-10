resource "aws_cloudwatch_log_group" "api_access" {
  name              = "/aws/apigateway/${local.application_name}-${local.component_name}"
  retention_in_days = 30
  tags              = local.tags
}

resource "aws_apigatewayv2_api" "upload_ticket" {
  name          = "${local.application_name}-${local.component_name}"
  protocol_type = "HTTP"

  cors_configuration {
    allow_headers = ["content-md5", "content-type"]
    allow_methods = ["OPTIONS", "POST"]
    allow_origins = ["*"]
    expose_headers = [
      "content-type",
    ]
    max_age = 300
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

resource "aws_apigatewayv2_route" "transfer_tickets" {
  api_id    = aws_apigatewayv2_api.upload_ticket.id
  route_key = "POST /transfer-tickets"
  target    = "integrations/${aws_apigatewayv2_integration.upload_ticket.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.upload_ticket.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_access.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      sourceIp       = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
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
