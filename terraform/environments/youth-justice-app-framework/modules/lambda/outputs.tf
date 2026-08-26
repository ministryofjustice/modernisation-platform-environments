output "lambda_arn" {
  value = aws_lambda_function.main.arn
}

output "function_name" {
  value = aws_lambda_function.main.function_name
}

output "log_group_name" {
  value = var.lambda.log_group != null ? aws_cloudwatch_log_group.log_group[0].name : null
}
