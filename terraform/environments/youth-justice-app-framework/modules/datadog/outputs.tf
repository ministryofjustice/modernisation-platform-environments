output "datadog_api_key_arn" {
  description = "The ARN of the secret that holds the Datadog Api Key."
  value       = aws_secretsmanager_secret.datadog_api.arn
}

output "datadog_firehose_iam_role_arn" {
  description = "The ARN of the IAM role used by the Firehose to send logs to Datadog."
  value       = aws_iam_role.cw_logs_to_firehose.arn
}

output "aws_kinesis_firehose_delivery_stream_arn" {
  description = "The ARN of the Kinesis Firehose delivery stream that sends logs to Datadog."
  value       = aws_kinesis_firehose_delivery_stream.to_datadog.arn
}

output "datadog_api_key_secret_arn" {
  description = "The ARN of the secret that holds the Datadog Api Key."
  value       = aws_secretsmanager_secret.datadog_api.arn
}

output "datadog_api_key_plain_secret_arn" {
  description = "The ARN of the secret that holds the Datadog Api Key."
  value       = aws_secretsmanager_secret.plain_datadog_api.arn
}
