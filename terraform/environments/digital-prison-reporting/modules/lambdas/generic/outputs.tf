output "lambda_function" {
  value = var.enable_lambda ? join("", aws_lambda_function.this.*.arn) : ""
}

output "lambda_name" {
  description = "The name of the Lambda function"
  value       = var.enable_lambda ? join("", aws_lambda_function.this.*.function_name)
}