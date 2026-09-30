locals {
  cloudwatch_metric_alarms = merge({
    for stage, queue_arn in local.hosted_pickup_dlq_arns : "${stage}-dlq-backlog" => {
      alarm_description   = "Unresolved ${stage} hosted pickup dead letters need investigation"
      comparison_operator = "GreaterThanThreshold"
      dimensions = {
        QueueName = split(":", queue_arn)[5]
      }
      evaluation_periods = 1
      metric_name        = "ApproximateNumberOfMessagesVisible"
      namespace          = "AWS/SQS"
      period             = 300
      statistic          = "Maximum"
      threshold          = 0
    }
    }, {
    "file-mover-errors" = {
      alarm_description   = "The hosted pickup mover has failed to process one or more messages"
      comparison_operator = "GreaterThanThreshold"
      dimensions          = { FunctionName = module.lambda_file_mover.lambda_function_name }
      evaluation_periods  = 1
      metric_name         = "Errors"
      namespace           = "AWS/Lambda"
      period              = 300
      statistic           = "Sum"
      threshold           = 0
    }
    "writer-record-failures" = {
      alarm_description   = "The hosted pickup writer returned one or more failed SQS records"
      comparison_operator = "GreaterThanThreshold"
      dimensions          = { ActionName = "push-to-s3-with-hosted-pickup" }
      evaluation_periods  = 1
      metric_name         = "WriterRecordFailed"
      namespace           = "ManagedFileTransfer"
      period              = 300
      statistic           = "Sum"
      threshold           = 0
    }
    "delivery-failed" = {
      alarm_description   = "The hosted pickup reporter published a failed delivery completion"
      comparison_operator = "GreaterThanThreshold"
      dimensions          = { ActionName = "push-to-s3-with-hosted-pickup" }
      evaluation_periods  = 1
      metric_name         = "DeliveryFailed"
      namespace           = "ManagedFileTransfer"
      period              = 300
      statistic           = "Sum"
      threshold           = 0
    }
    "file-mover-throttles" = {
      alarm_description   = "The hosted pickup mover has been throttled"
      comparison_operator = "GreaterThanThreshold"
      dimensions          = { FunctionName = module.lambda_file_mover.lambda_function_name }
      evaluation_periods  = 1
      metric_name         = "Throttles"
      namespace           = "AWS/Lambda"
      period              = 300
      statistic           = "Sum"
      threshold           = 0
    }
    "file-mover-duration" = {
      alarm_description   = "The hosted pickup mover duration is approaching its 900-second timeout"
      comparison_operator = "GreaterThanThreshold"
      datapoints_to_alarm = 2
      dimensions          = { FunctionName = module.lambda_file_mover.lambda_function_name }
      evaluation_periods  = 2
      metric_name         = "Duration"
      namespace           = "AWS/Lambda"
      period              = 300
      statistic           = "Average"
      threshold           = 840000
    }
    "dlq-reporter-errors" = {
      alarm_description   = "The hosted pickup DLQ reporter has failed to process one or more messages"
      comparison_operator = "GreaterThanThreshold"
      dimensions          = { FunctionName = module.lambda_dlq_reporter.lambda_function_name }
      evaluation_periods  = 1
      metric_name         = "Errors"
      namespace           = "AWS/Lambda"
      period              = 300
      statistic           = "Sum"
      threshold           = 0
    }
    "reporter-record-failures" = {
      alarm_description   = "The hosted pickup DLQ reporter returned one or more failed SQS records"
      comparison_operator = "GreaterThanThreshold"
      dimensions          = { ActionName = "push-to-s3-with-hosted-pickup" }
      evaluation_periods  = 1
      metric_name         = "ReporterRecordFailed"
      namespace           = "ManagedFileTransfer"
      period              = 300
      statistic           = "Sum"
      threshold           = 0
    }
    "dlq-reporter-throttles" = {
      alarm_description   = "The hosted pickup DLQ reporter has been throttled"
      comparison_operator = "GreaterThanThreshold"
      dimensions          = { FunctionName = module.lambda_dlq_reporter.lambda_function_name }
      evaluation_periods  = 1
      metric_name         = "Throttles"
      namespace           = "AWS/Lambda"
      period              = 300
      statistic           = "Sum"
      threshold           = 0
    }
    "dlq-reporter-duration" = {
      alarm_description   = "The hosted pickup DLQ reporter duration is approaching its 60-second timeout"
      comparison_operator = "GreaterThanThreshold"
      datapoints_to_alarm = 2
      dimensions          = { FunctionName = module.lambda_dlq_reporter.lambda_function_name }
      evaluation_periods  = 2
      metric_name         = "Duration"
      namespace           = "AWS/Lambda"
      period              = 300
      statistic           = "Average"
      threshold           = 55000
    }
    "processing-oldest-message-age" = {
      alarm_description   = "The oldest hosted pickup processing message has been waiting for 15 minutes"
      comparison_operator = "GreaterThanThreshold"
      dimensions          = { QueueName = module.sqs_hosted_pickup.queue_name }
      evaluation_periods  = 1
      metric_name         = "ApproximateAgeOfOldestMessage"
      namespace           = "AWS/SQS"
      period              = 300
      statistic           = "Maximum"
      threshold           = 900
    }
  })

  high_priority_alarm_names = toset(concat(
    [for stage, queue_arn in local.hosted_pickup_dlq_arns : "${stage}-dlq-backlog"],
    ["delivery-failed"],
  ))

  low_priority_alarm_names = toset([
    "file-mover-errors",
    "writer-record-failures",
    "file-mover-throttles",
    "file-mover-duration",
    "dlq-reporter-errors",
    "reporter-record-failures",
    "dlq-reporter-throttles",
    "dlq-reporter-duration",
    "processing-oldest-message-age",
  ])

  high_priority_alarm_actions = local.is-production ? [data.aws_sns_topic.pagerduty["high-priority"].arn] : [data.aws_sns_topic.pagerduty["low-priority"].arn]
  low_priority_alarm_actions  = local.is-production ? [data.aws_sns_topic.pagerduty["low-priority"].arn] : []

  cloudwatch_alarm_actions = merge(
    { for alarm_name in local.high_priority_alarm_names : alarm_name => local.high_priority_alarm_actions },
    { for alarm_name in local.low_priority_alarm_names : alarm_name => local.low_priority_alarm_actions },
  )
}