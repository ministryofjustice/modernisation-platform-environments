output "rest_api_id" {
  description = "The ID of the REST API ID"
  value       = aws_api_gateway_rest_api.this.id
}

output "rest_api_arn" {
  description = "The ARN of the REST API ARN"
  value       = aws_api_gateway_rest_api.this.arn
}

output "rest_api_execution_arn" {
  description = "The ARN of the REST API ARN"
  value       = aws_api_gateway_rest_api.this.execution_arn
}