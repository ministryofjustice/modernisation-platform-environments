resource "aws_cloudwatch_log_group" "api_access" {
  name              = "/aws/apigateway/${local.resource_name_prefix}"
  kms_key_id        = module.kms_cloudwatch_logs.key_arn
  retention_in_days = 365
  tags              = local.tags
}

resource "aws_apigatewayv2_vpc_link" "service" {
  name               = "${local.resource_name_prefix}-${local.environment}"
  security_group_ids = [aws_security_group.api_gateway_vpc_link.id]
  subnet_ids         = var.private_subnet_ids
  tags               = local.tags
}

resource "aws_apigatewayv2_api" "service" {
  name          = local.resource_name_prefix
  protocol_type = "HTTP"
  tags          = local.tags
}

resource "aws_apigatewayv2_integration" "service" {
  api_id                 = aws_apigatewayv2_api.service.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.service.id
  integration_uri        = aws_lb_listener.service.arn
  payload_format_version = "1.0"
  timeout_milliseconds   = 30000
}

resource "aws_apigatewayv2_route" "root" {
  #checkov:skip=CKV_AWS_309:Authentication is enforced by the downstream application using Basic auth
  api_id    = aws_apigatewayv2_api.service.id
  route_key = "ANY /"
  target    = "integrations/${aws_apigatewayv2_integration.service.id}"
}

resource "aws_apigatewayv2_route" "proxy" {
  #checkov:skip=CKV_AWS_309:Authentication is enforced by the downstream application using Basic auth
  api_id    = aws_apigatewayv2_api.service.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.service.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.service.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    detailed_metrics_enabled = true
    throttling_rate_limit    = 50
    throttling_burst_limit   = 100
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
    })
  }

  tags = local.tags
}
