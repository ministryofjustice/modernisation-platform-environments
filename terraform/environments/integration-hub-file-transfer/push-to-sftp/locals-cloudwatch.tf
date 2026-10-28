locals {
  cloudwatch_metric_alarms = merge({
    for stage, queue_arn in local.dlq_arns : "${stage}-dlq-backlog" => {
      alarm_description  = "Unresolved ${stage} push-to-sftp dead letters need investigation"
      dimensions         = { QueueName = split(":", queue_arn)[5] }
      evaluation_periods = 1
      metric_name        = "ApproximateNumberOfMessagesVisible"
      namespace          = "AWS/SQS"
      statistic          = "Maximum"
      threshold          = 0
    }
    }, {
    "file-mover-errors" = {
      alarm_description  = "The push-to-sftp writer failed to process messages"
      dimensions         = { FunctionName = module.lambda_file_mover.lambda_function_name }
      evaluation_periods = 1
      metric_name        = "Errors"
      namespace          = "AWS/Lambda"
      statistic          = "Sum"
      threshold          = 0
    }
    "writer-record-failures" = {
      alarm_description  = "The push-to-sftp writer returned failed SQS records"
      dimensions         = { ActionName = "push-to-sftp", service = local.pattern_name }
      evaluation_periods = 1
      metric_name        = "WriterRecordFailed"
      namespace          = "ManagedFileTransfer"
      statistic          = "Sum"
      threshold          = 0
    }
    "delivery-failed" = {
      alarm_description  = "A failed SFTP delivery completion was published; investigate and resolve the incident manually"
      dimensions         = { ActionName = "push-to-sftp", service = "${local.pattern_name}-dlq-reporter" }
      evaluation_periods = 1
      metric_name        = "DeliveryFailed"
      namespace          = "ManagedFileTransfer"
      statistic          = "Sum"
      threshold          = 0
    }
    "file-mover-throttles" = {
      alarm_description  = "The push-to-sftp writer has been throttled"
      dimensions         = { FunctionName = module.lambda_file_mover.lambda_function_name }
      evaluation_periods = 1
      metric_name        = "Throttles"
      namespace          = "AWS/Lambda"
      statistic          = "Sum"
      threshold          = 0
    }
    "file-mover-duration" = {
      alarm_description   = "The SFTP writer is approaching its 900-second timeout"
      datapoints_to_alarm = 2
      dimensions          = { FunctionName = module.lambda_file_mover.lambda_function_name }
      evaluation_periods  = 2
      metric_name         = "Duration"
      namespace           = "AWS/Lambda"
      statistic           = "Average"
      threshold           = 840000
    }
    "dlq-reporter-errors" = {
      alarm_description  = "The push-to-sftp DLQ reporter failed to process messages"
      dimensions         = { FunctionName = module.lambda_dlq_reporter.lambda_function_name }
      evaluation_periods = 1
      metric_name        = "Errors"
      namespace          = "AWS/Lambda"
      statistic          = "Sum"
      threshold          = 0
    }
    "reporter-record-failures" = {
      alarm_description  = "The push-to-sftp DLQ reporter returned failed SQS records"
      dimensions         = { ActionName = "push-to-sftp", service = "${local.pattern_name}-dlq-reporter" }
      evaluation_periods = 1
      metric_name        = "ReporterRecordFailed"
      namespace          = "ManagedFileTransfer"
      statistic          = "Sum"
      threshold          = 0
    }
    "dlq-reporter-throttles" = {
      alarm_description  = "The push-to-sftp DLQ reporter has been throttled"
      dimensions         = { FunctionName = module.lambda_dlq_reporter.lambda_function_name }
      evaluation_periods = 1
      metric_name        = "Throttles"
      namespace          = "AWS/Lambda"
      statistic          = "Sum"
      threshold          = 0
    }
    "dlq-reporter-duration" = {
      alarm_description   = "The SFTP DLQ reporter is approaching its 60-second timeout"
      datapoints_to_alarm = 2
      dimensions          = { FunctionName = module.lambda_dlq_reporter.lambda_function_name }
      evaluation_periods  = 2
      metric_name         = "Duration"
      namespace           = "AWS/Lambda"
      statistic           = "Average"
      threshold           = 55000
    }
    "processing-oldest-message-age" = {
      alarm_description  = "The oldest SFTP processing message has been waiting for 15 minutes"
      dimensions         = { QueueName = module.sqs_processing.queue_name }
      evaluation_periods = 1
      metric_name        = "ApproximateAgeOfOldestMessage"
      namespace          = "AWS/SQS"
      statistic          = "Maximum"
      threshold          = 900
    }
  })

  high_priority_alarm_names = toset(concat(
    [for stage in keys(local.dlq_arns) : "${stage}-dlq-backlog"],
    ["delivery-failed"],
  ))

  high_priority_alarm_actions = local.is-production ? [data.aws_sns_topic.pagerduty["high-priority"].arn] : [data.aws_sns_topic.pagerduty["low-priority"].arn]
  low_priority_alarm_actions  = local.is-production ? [data.aws_sns_topic.pagerduty["low-priority"].arn] : []

  cloudwatch_alarm_actions = {
    for name in keys(local.cloudwatch_metric_alarms) : name => (
      contains(local.high_priority_alarm_names, name) ? local.high_priority_alarm_actions : local.low_priority_alarm_actions
    )
  }
}