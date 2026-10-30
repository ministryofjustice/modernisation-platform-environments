module "api_access_log_group" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for pinned versions
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "5.7.2"

  name              = "/aws/apigateway/${local.resource_name_prefix}"
  kms_key_id        = module.kms_cloudwatch_logs.key_arn
  retention_in_days = 30
  tags              = local.tags
}

module "api_gateway" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for pinned versions
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "6.1.0"

  name          = local.resource_name_prefix
  protocol_type = "HTTP"
  region        = local.region

  create_domain_name             = false
  create_routes_and_integrations = false
  create_stage                   = false

  tags = local.tags
}

# Sends the request straight to EventBridge PutEvents, with no Lambda in between.
# The event name comes from the path and the whole request body becomes the event detail,
# so the body must be a JSON object. Clients send {} when there is no payload.
resource "aws_apigatewayv2_integration" "put_events" {
  api_id              = module.api_gateway.api_id
  integration_type    = "AWS_PROXY"
  integration_subtype = "EventBridge-PutEvents"
  credentials_arn     = aws_iam_role.api_gateway_put_events.arn

  request_parameters = {
    EventBusName = module.eventbridge_bus.eventbridge_bus_name
    Source       = local.event_source
    DetailType   = "$request.path.eventName"
    Detail       = "$request.body"
  }
}

# Authentication is deliberately not configured yet; only use this in the development account.
resource "aws_apigatewayv2_route" "publish_event" {
  #checkov:skip=CKV_AWS_309:Authorisation is deferred until the first version has been validated in development
  api_id             = module.api_gateway.api_id
  route_key          = "POST /events/{eventName}"
  target             = "integrations/${aws_apigatewayv2_integration.put_events.id}"
  authorization_type = "NONE"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = module.api_gateway.api_id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    detailed_metrics_enabled = true
    # Omitted limits in this block are sent as zero by the provider, blocking requests.
    throttling_rate_limit  = 10
    throttling_burst_limit = 20
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
    })
  }

  tags = local.tags
}
