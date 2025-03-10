output "api_gateway_id" {
  value = aws_api_gateway_rest_api.api_gateway.id
}

output "api_gateway_stage_name" {
  value = aws_api_gateway_deployment.deployment.stage_name
}
