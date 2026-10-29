output "arn" {
  description = "ARN of the Lambda function."
  value       = aws_lambda_function.quarantine.arn
}

output "name" {
  description = "Name of the Lambda function."
  value       = aws_lambda_function.quarantine.function_name
}