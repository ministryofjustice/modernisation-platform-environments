output "gateway_id" {
  description = "ID of the API gateway"
  value       = aws_api_gateway_rest_api.data_platform.id
}

output "root_resource_id" {
  value = aws_api_gateway_rest_api.data_platform.root_resource_id
}

output "authorizor_id" {
  value = aws_api_gateway_authorizer.authorizer.id
}
