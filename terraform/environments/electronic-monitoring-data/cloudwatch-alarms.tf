data "aws_sqs_queue" "load_mdss_dlq" {
  name = "load_mdss-dlq"
}

resource "aws_cloudwatch_metric_alarm" "load_mdss_dlq_alarm" {
  alarm_name          = "load_mdss_dlq_has_messages"
  alarm_description   = "Triggered when Load MDSS DLQ contains messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 0
  treat_missing_data  = "notBreaching"

  metric_name = "ApproximateNumberOfMessagesVisible"
  namespace   = "AWS/SQS"
  period      = 60
  statistic   = "Sum"

  dimensions = {
    QueueName = data.aws_sqs_queue.load_mdss_dlq.name
  }

  alarm_actions = [
    aws_sns_topic.emds_alerts.arn
  ]
}

resource "aws_cloudwatch_metric_alarm" "clean_mdss_dlq_alarm" {
  alarm_name          = "clean_mdss_dlq_has_messages"
  alarm_description   = "Triggered when cleanup MDSS DLQ receives failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 0
  treat_missing_data  = "notBreaching"

  metric_name   = "ApproximateNumberOfMessagesVisible"
  namespace     = "AWS/SQS"
  period        = 60
  statistic     = "Sum"

  dimensions = {
    QueueName = aws_sqs_queue.clean_mdss_load_dlq.name
  }

  alarm_actions = [
    aws_sns_topic.emds_alerts.arn
  ]
}
