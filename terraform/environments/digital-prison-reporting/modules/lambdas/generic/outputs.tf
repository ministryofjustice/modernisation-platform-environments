output "lambda_function" {
  value       = var.enable_lambda ? join("", aws_lambda_function.this.*.arn) : ""
}