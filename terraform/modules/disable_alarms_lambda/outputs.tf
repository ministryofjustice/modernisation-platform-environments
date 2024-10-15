output "lambda_function_arn" {
  description = "The ARN of the Lambda function"
  value       = aws_lambda_function.disable_alarms.arn
}

output "lambda_function_name" {
  description = "The name of the Lambda function"
  value       = aws_lambda_function.disable_alarms.function_name
}

# output "cloudwatch_event_rule_arns" {
#   description = "The ARNs of the CloudWatch Event Rules"
#   value       = { for k, v in aws_cloudwatch_event_rule.alarm_scheduler : k => v.arn }
# }
