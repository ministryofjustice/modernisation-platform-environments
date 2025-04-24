output "lambda_arn" {
  value = aws_lambda_function.main.arn
}

output "function_name" {
  value = aws_lambda_function.main.function_name
}
