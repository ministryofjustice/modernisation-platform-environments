module "api_gateway" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "6.1.0"

  name          = local.resource_name_prefix
  protocol_type = "HTTP"
  region        = local.region

  cors_configuration = length(local.api_configuration.cors_allowed_origins) > 0 ? {
    allow_headers  = ["authorization", "content-md5", "content-type"]
    allow_methods  = ["DELETE", "OPTIONS", "POST"]
    allow_origins  = local.api_configuration.cors_allowed_origins
    expose_headers = ["content-type"]
    max_age        = 300
  } : null

  authorizers = {
    mft_request = {
      authorizer_type                   = "REQUEST"
      name                              = "${local.resource_name_prefix}-authorizer"
      authorizer_uri                    = module.lambda_api_authorizer.lambda_function_invoke_arn
      authorizer_payload_format_version = "2.0"
      enable_simple_responses           = true
      identity_sources                  = ["$request.header.Authorization"]
    }
  }

  create_domain_name             = false
  create_routes_and_integrations = false
  create_stage                   = false

  tags = var.tags
}

resource "aws_apigatewayv2_integration" "upload_ticket" {
  api_id                 = module.api_gateway.api_id
  integration_type       = "AWS_PROXY"
  integration_uri        = module.lambda_upload_ticket.lambda_function_invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "api_docs" {
  api_id                 = module.api_gateway.api_id
  integration_type       = "AWS_PROXY"
  integration_uri        = module.lambda_api_docs.lambda_function_invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "transfer_tickets" {
  api_id             = module.api_gateway.api_id
  route_key          = "POST /transfer-tickets"
  target             = "integrations/${aws_apigatewayv2_integration.upload_ticket.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = module.api_gateway.authorizers["mft_request"].id
}

resource "aws_apigatewayv2_route" "transfer_ticket_parts" {
  api_id             = module.api_gateway.api_id
  route_key          = "POST /transfer-tickets/{transferTicket}/parts"
  target             = "integrations/${aws_apigatewayv2_integration.upload_ticket.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = module.api_gateway.authorizers["mft_request"].id
}

resource "aws_apigatewayv2_route" "transfer_ticket_complete" {
  api_id             = module.api_gateway.api_id
  route_key          = "POST /transfer-tickets/{transferTicket}/complete"
  target             = "integrations/${aws_apigatewayv2_integration.upload_ticket.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = module.api_gateway.authorizers["mft_request"].id
}

resource "aws_apigatewayv2_route" "transfer_ticket_abort" {
  api_id             = module.api_gateway.api_id
  route_key          = "DELETE /transfer-tickets/{transferTicket}"
  target             = "integrations/${aws_apigatewayv2_integration.upload_ticket.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = module.api_gateway.authorizers["mft_request"].id
}

resource "aws_apigatewayv2_route" "api_docs" {
  api_id    = module.api_gateway.api_id
  route_key = "GET /docs"
  target    = "integrations/${aws_apigatewayv2_integration.api_docs.id}"
}

resource "aws_apigatewayv2_route" "api_openapi_contract" {
  api_id    = module.api_gateway.api_id
  route_key = "GET /openapi.yaml"
  target    = "integrations/${aws_apigatewayv2_integration.api_docs.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = module.api_gateway.api_id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    detailed_metrics_enabled = true
  }

  access_log_settings {
    destination_arn = module.api_access_log_group.cloudwatch_log_group_arn
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

  tags = var.tags
}

resource "aws_lambda_permission" "allow_api_gateway_upload_ticket" {
  statement_id  = "AllowExecutionFromApiGatewayUploadTicket"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_upload_ticket.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_api_gateway_authorizer" {
  statement_id  = "AllowExecutionFromApiGatewayAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_api_authorizer.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/authorizers/${module.api_gateway.authorizers["mft_request"].id}"
}

resource "aws_lambda_permission" "allow_api_gateway_api_docs" {
  statement_id  = "AllowExecutionFromApiGatewayApiDocs"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_api_docs.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/*/*"
}