output "lambda_function" {
  value = join(",", aws_lambda_function.*.this)
}