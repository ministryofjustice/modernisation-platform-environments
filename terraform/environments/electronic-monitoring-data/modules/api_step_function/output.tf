output "api_gateway_id" {
  value = aws_api_gateway_rest_api.api_gateway.id
}

output "api_gateway_arn" {
  value = aws_api_gateway_rest_api.api_gateway.arn
}

output "resource_request_id" {
  value = aws_api_gateway_resource.resource.id
}

output "resource_status_id" {
  value = aws_api_gateway_resource.status[0].id
}

output "resource_execution_id_id" {
  value = aws_api_gateway_resource.execution_id[0].id
}
