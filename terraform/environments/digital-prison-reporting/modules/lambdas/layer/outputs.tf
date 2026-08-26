# Lambda Layer
output "lambda_layer_arn" {
  description = "The ARN of the Lambda Layer with version"
  value       = try(aws_lambda_layer_version.this[0].arn, "")
}

output "lambda_layer_layer_arn" {
  description = "The ARN of the Lambda Layer without version"
  value       = try(aws_lambda_layer_version.this[0].layer_arn, "")
}

output "lambda_layer_created_date" {
  description = "The date Lambda Layer resource was created"
  value       = try(aws_lambda_layer_version.this[0].created_date, "")
}

output "lambda_layer_source_code_size" {
  description = "The size in bytes of the Lambda Layer .zip file"
  value       = try(aws_lambda_layer_version.this[0].source_code_size, "")
}

output "lambda_layer_version" {
  description = "The Lambda Layer version"
  value       = try(aws_lambda_layer_version.this[0].version, "")
}