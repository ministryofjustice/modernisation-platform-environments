####################
# Outputs
####################

output "cloudfront_waiting_room_domain" {
  description = "CloudFront domain name for the waiting room / authentication entry point"
  value       = local.create_resources ? aws_cloudfront_distribution.waiting_room[0].domain_name : null
}

output "cloudfront_waiting_room_url" {
  description = "Full CloudFront URL for the waiting room (use with ?login_hint=email)"
  value       = local.create_resources ? "https://${aws_cloudfront_distribution.waiting_room[0].domain_name}" : null
}

output "api_gateway_callback_endpoint" {
  description = "API Gateway endpoint for OAuth callback"
  value       = local.create_resources ? aws_apigatewayv2_api.callback[0].api_endpoint : null
}

output "callback_url" {
  description = "Full callback URL (register this in Azure Entra ID app)"
  value       = local.create_resources ? "${aws_apigatewayv2_api.callback[0].api_endpoint}/callback" : null
}

output "workspaces_portal_external_1_url" {
  description = "WorkSpaces Web portal URL for external_1"
  value       = local.create_resources ? "https://${aws_workspacesweb_portal.external["external_1"].portal_endpoint}" : null
}
