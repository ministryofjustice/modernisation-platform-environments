# ------------------------------------------------------------------------------
# GitHub Project webhook
# ------------------------------------------------------------------------------

resource "aws_apigatewayv2_api" "live_feed_github_webhook" {
  name          = "live-feed-github-webhook-${local.environment_shorthand}"
  protocol_type = "HTTP"

  tags = local.tags
}

resource "aws_apigatewayv2_integration" "live_feed_github_webhook" {
  api_id = aws_apigatewayv2_api.live_feed_github_webhook.id

  integration_type   = "AWS_PROXY"
  integration_method = "POST"

  integration_uri = format(
    "arn:aws:apigateway:%s:lambda:path/2015-03-31/functions/%s/invocations",
    data.aws_region.current.name,
    module.live_feed_incident_manager.lambda_function_arn,
  )

  payload_format_version = "2.0"
  timeout_milliseconds   = 30000
}

resource "aws_apigatewayv2_route" "live_feed_github_project_status" {
  api_id = aws_apigatewayv2_api.live_feed_github_webhook.id

  route_key          = "POST /github/project-status"
  authorization_type = "NONE"
  target = (
    "integrations/${aws_apigatewayv2_integration.live_feed_github_webhook.id}"
  )
}

resource "aws_apigatewayv2_stage" "live_feed_github_webhook" {
  api_id = aws_apigatewayv2_api.live_feed_github_webhook.id

  name        = "$default"
  auto_deploy = true

  tags = local.tags
}

output "live_feed_github_webhook_url" {
  description = "GitHub App webhook URL for live-feed Project status events"

  value = format(
    "%s/github/project-status",
    aws_apigatewayv2_api.live_feed_github_webhook.api_endpoint,
  )
}