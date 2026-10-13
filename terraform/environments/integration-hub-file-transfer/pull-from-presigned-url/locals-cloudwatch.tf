locals {
  monitored_queues = {
    eventbridge = module.sqs_notifications_eventbridge_dlq.queue_name
    sns         = module.sqs_notifications_sns_dlq.queue_name
    processing  = module.sqs_notifications_dlq.queue_name
  }
  cloudwatch_metric_alarms = merge({
    for stage, queue in local.monitored_queues : "${stage}-dlq" => {
      alarm_description   = "Unresolved ${stage} pickup dead letters need investigation"
      comparison_operator = "GreaterThanThreshold"
      dimensions          = { QueueName = queue }
      evaluation_periods  = 1
      metric_name         = "ApproximateNumberOfMessagesVisible"
      namespace           = "AWS/SQS"
      period              = 300
      statistic           = "Maximum"
      threshold           = 0
    }
    }, {
    "errors" = {
      alarm_description   = "Notifier invocation failed"
      comparison_operator = "GreaterThanThreshold"
      dimensions          = { FunctionName = module.lambda_notifier.lambda_function_name }
      evaluation_periods  = 1
      metric_name         = "Errors"
      namespace           = "AWS/Lambda"
      period              = 300
      statistic           = "Sum"
      threshold           = 0
    }
    "record-failures" = {
      alarm_description   = "Notifier returned failed SQS records"
      comparison_operator = "GreaterThanThreshold"
      dimensions          = {}
      evaluation_periods  = 1
      metric_name         = "RecordFailures"
      namespace           = "IntegrationHub/SlackPickup"
      period              = 300
      statistic           = "Sum"
      threshold           = 0
    }
    "throttles" = {
      alarm_description   = "Notifier has been throttled"
      comparison_operator = "GreaterThanThreshold"
      dimensions          = { FunctionName = module.lambda_notifier.lambda_function_name }
      evaluation_periods  = 1
      metric_name         = "Throttles"
      namespace           = "AWS/Lambda"
      period              = 300
      statistic           = "Sum"
      threshold           = 0
    }
    "duration" = {
      alarm_description   = "Notifier is approaching its 900-second timeout"
      comparison_operator = "GreaterThanThreshold"
      dimensions          = { FunctionName = module.lambda_notifier.lambda_function_name }
      evaluation_periods  = 1
      metric_name         = "Duration"
      namespace           = "AWS/Lambda"
      period              = 300
      statistic           = "Average"
      threshold           = 840000
    }
    "processing-oldest-message-age" = {
      alarm_description   = "Pickup messages have waited more than 15 minutes"
      comparison_operator = "GreaterThanThreshold"
      dimensions          = { QueueName = module.sqs_notifications.queue_name }
      evaluation_periods  = 1
      metric_name         = "ApproximateAgeOfOldestMessage"
      namespace           = "AWS/SQS"
      period              = 300
      statistic           = "Maximum"
      threshold           = 900
    }
  })
  high_priority_alarm_actions = local.is-production ? [data.aws_sns_topic.pagerduty["high-priority"].arn] : [data.aws_sns_topic.pagerduty["low-priority"].arn]
  low_priority_alarm_actions  = local.is-production ? [data.aws_sns_topic.pagerduty["low-priority"].arn] : []
  cloudwatch_alarm_actions = {
    for name in keys(local.cloudwatch_metric_alarms) : name => contains([for stage in keys(local.monitored_queues) : "${stage}-dlq"], name) ? local.high_priority_alarm_actions : local.low_priority_alarm_actions
  }
}
