# Lambda
output "lambda_function" {
  value = var.enable_lambda ? join("", aws_lambda_function.this.*.arn) : ""
}

output "lambda_name" {
  description = "The name of the Lambda function"
  value       = var.enable_lambda ? join("", aws_lambda_function.this.*.function_name) : ""
}

output "lambda_function_arn" {
  value = var.enable_lambda ? join("", aws_lambda_function.this.*.arn) : ""
}

output "lambda_invoke_arn" {
  value = var.enable_lambda ? join("", aws_lambda_function.this.*.invoke_arn) : ""
}

output "lambda_execution_role_id" {
  description = "ID of the lambda execution role. Can be used to attach additional policies through aws_iam_role_policy_attachment"
  value       = var.enable_lambda ? aws_iam_role.lambda_execution_role[0].id : ""
}
