locals {
  monitored_queues = {
    eventbridge = module.sqs_notifications_eventbridge_dlq.queue_name
    sns         = module.sqs_notifications_sns_dlq.queue_name
    processing  = module.sqs_notifications_dlq.queue_name
  }
}
resource "aws_cloudwatch_metric_alarm" "dlq" {
  for_each            = local.monitored_queues
  alarm_name          = "${local.pattern_name}-${each.key}-dlq"
  alarm_description   = "Slack pickup notifications need investigation; do not replay expired files."
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  dimensions          = { QueueName = each.value }
  tags                = local.tags
}
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${local.pattern_name}-errors"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  dimensions          = { FunctionName = module.lambda_notifier.lambda_function_name }
  tags                = local.tags
}
resource "aws_cloudwatch_log_metric_filter" "record_failures" {
  name           = "${local.pattern_name}-record-failures"
  log_group_name = module.lambda_notifier.lambda_cloudwatch_log_group_name
  pattern        = "{ $.outcome = \"failed\" }"
  metric_transformation {
    name      = "RecordFailures"
    namespace = "IntegrationHub/SlackPickup"
    value     = "1"
  }
}
resource "aws_cloudwatch_metric_alarm" "record_failures" {
  alarm_name          = "${local.pattern_name}-record-failures"
  namespace           = "IntegrationHub/SlackPickup"
  metric_name         = "RecordFailures"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  tags                = local.tags
}
output "portal_url" { value = local.portal_url }
output "webhook_secret_names" {
  value = { for id, secret in aws_secretsmanager_secret.webhook : id => secret.name }
}
