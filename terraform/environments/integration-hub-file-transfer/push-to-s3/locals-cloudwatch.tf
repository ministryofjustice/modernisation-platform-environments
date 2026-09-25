locals {
  cloudwatch_metric_alarms = merge({
    for stage, queue_arn in local.push_to_s3_dlq_arns : "${stage}-dlq-backlog" => {
      alarm_description   = "Unresolved ${stage} push-to-s3 dead letters need investigation"
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
      alarm_description   = "The push-to-s3 mover has failed to process one or more messages"
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
      alarm_description   = "The push-to-s3 writer returned one or more failed SQS records"
      comparison_operator = "GreaterThanThreshold"
      dimensions          = { ActionName = "push-to-s3" }
      evaluation_periods  = 1
      metric_name         = "WriterRecordFailed"
      namespace           = "ManagedFileTransfer"
      period              = 300
      statistic           = "Sum"
      threshold           = 0
    }
    "file-mover-throttles" = {
      alarm_description   = "The push-to-s3 mover has been throttled"
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
      alarm_description   = "The push-to-s3 mover duration is approaching its 900-second timeout"
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
      alarm_description   = "The push-to-s3 DLQ reporter has failed to process one or more messages"
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
      alarm_description   = "The push-to-s3 DLQ reporter returned one or more failed SQS records"
      comparison_operator = "GreaterThanThreshold"
      dimensions          = { ActionName = "push-to-s3" }
      evaluation_periods  = 1
      metric_name         = "ReporterRecordFailed"
      namespace           = "ManagedFileTransfer"
      period              = 300
      statistic           = "Sum"
      threshold           = 0
    }
    "dlq-reporter-throttles" = {
      alarm_description   = "The push-to-s3 DLQ reporter has been throttled"
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
      alarm_description   = "The push-to-s3 DLQ reporter duration is approaching its 60-second timeout"
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
      alarm_description   = "The oldest push-to-s3 processing message has been waiting for 15 minutes"
      comparison_operator = "GreaterThanThreshold"
      dimensions          = { QueueName = module.sqs_push_to_s3.queue_name }
      evaluation_periods  = 1
      metric_name         = "ApproximateAgeOfOldestMessage"
      namespace           = "AWS/SQS"
      period              = 300
      statistic           = "Maximum"
      threshold           = 900
    }
  })
}