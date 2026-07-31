output "api_gateway_id" {
  value = aws_api_gateway_rest_api.api_gateway.id
}

output "api_gateway_arn" {
  value = aws_api_gateway_rest_api.api_gateway.arn
}

output "resource_request_id" {
  value = aws_api_gateway_resource.resource.id
}