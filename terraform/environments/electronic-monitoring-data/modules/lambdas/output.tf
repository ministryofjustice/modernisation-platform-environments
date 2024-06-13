output "lambda_function_name" {
  value = aws_lambda_function.this.function_name
}

output "lambda_function_arn" {
  value = aws_lambda_function.this.arn
}

output "lambda_function_invoke_arn" {
  value = aws_lambda_function.this.invoke_arn
}
