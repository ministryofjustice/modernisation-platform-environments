output "lambda_function_name" {
  value = module.this.function_name
}

output "lambda_function_arn" {
  value = module.this.arn
}

output "lambda_function_invoke_arn" {
  value = module.this.invoke_arn
}