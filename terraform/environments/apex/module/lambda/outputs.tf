output "lambda_function" {
  value = aws_lambda_function.snapshotDBFunction.*.arn
}

output "lambda_function_name" {
  value = aws_lambda_function.snapshotDBFunction.*.function_name
}