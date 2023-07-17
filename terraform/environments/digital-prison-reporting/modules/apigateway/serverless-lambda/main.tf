# Gateway Resource
resource "aws_apigatewayv2_api" "this" {
  count         = var.enable_gateway ? 1 : 0

  name          = "${var.name}-gw"
  protocol_type = "HTTP"

  tags          = var.tags
}

resource "aws_apigatewayv2_stage" "this" {
  count       = var.enable_gateway ? 1 : 0

  api_id      = aws_apigatewayv2_api.this[0].id

  name        = "${var.name}-stage"
  auto_deploy = true
  tags        = var.tags

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.this[0].arn

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

# Lambda Integration
resource "aws_apigatewayv2_integration" "this" {
  count               = var.enable_gateway ? 1 : 0

  api_id              = aws_apigatewayv2_api.this[0].id
  connection_id       = aws_apigatewayv2_vpc_link.this[0].id
  integration_uri     = var.lambda_arn
  integration_type    = "AWS_PROXY"
  integration_method  = "POST"
}

# Endpoint Route
resource "aws_apigatewayv2_route" "this" {
  count     = var.enable_gateway ? 1 : 0

  api_id    = aws_apigatewayv2_api.this[0].id

  route_key = "ANY /domain"
  target    = "integrations/${aws_apigatewayv2_integration.this[0].id}"
}

# LogGroup
resource "aws_cloudwatch_log_group" "this" {
  count               = var.enable_gateway ? 1 : 0

  name                = "/aws/api_gw/${aws_apigatewayv2_api.this[0].name}"
  retention_in_days   = 30
  tags                = var.tags
}

# Endpoint Route
resource "aws_apigatewayv2_vpc_link" "this" {
  count              = var.enable_gateway ? 1 : 0

  name               = "${var.name}-vpclink"
  security_group_ids = var.security_group_ids
  subnet_ids         = var.subnet_ids

  tags               = var.tags
}

# Lambda Permissions
resource "aws_lambda_permission" "this" {
  count         = var.enable_gateway ? 1 : 0

  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}
