output "lambda_function_arn" {
  description = "The ARN of the Connector Lambda function"
  value       = aws_lambda_function.athena_federated_query_lambda.arn
}
