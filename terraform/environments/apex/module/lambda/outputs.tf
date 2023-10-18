output "lambda_function" {
  value = aws_lambda_function.snapshotDBFunction.*.arn[count.index]
}

output "lambda_function_name" {
  value = aws_lambda_function.snapshotDBFunction.*.function_name[count.index]
}