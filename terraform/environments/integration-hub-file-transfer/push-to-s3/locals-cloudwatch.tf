locals {
  cloudwatch_metric_alarms = {
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
  }
}