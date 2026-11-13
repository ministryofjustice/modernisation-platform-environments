output "resource_request_id" {
  value = aws_api_gateway_resource.resource.id
}

output "resource_status_id" {
  value = var.enable_status_check ? aws_api_gateway_resource.status[0].id : null
}

output "resource_execution_id_id" {
  value = var.enable_status_check ? aws_api_gateway_resource.execution_id[0].id : null
}

output "method_id" {
  value = aws_api_gateway_method.method.id
}

output "status_method_id" {
  value = var.enable_status_check ? aws_api_gateway_method.get_status[0].id : null
}

output "integration_id" {
  value = aws_api_gateway_integration.step_function_integration.id
}

output "status_integration_id" {
  value = var.enable_status_check ? aws_api_gateway_integration.status_integration[0].id : null
}
