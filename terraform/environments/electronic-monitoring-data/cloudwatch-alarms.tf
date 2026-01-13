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
    QueueName = module.load_mdss_event_queue.sqs_dlq.name
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

  metric_name = "ApproximateNumberOfMessagesVisible"
  namespace   = "AWS/SQS"
  period      = 60
  statistic   = "Sum"

  dimensions = {
    QueueName = module.load_mdss_event_queue.sqs_dlq.name
  }

  alarm_actions = [
    aws_sns_topic.emds_alerts.arn
  ]
}

resource "aws_cloudwatch_metric_alarm" "glue_database_count_high" {
  alarm_name          = "glue_database_count_high"
  alarm_description   = "Triggered when Glue database count is above 8000 (approaching 10k limit)"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 8000
  treat_missing_data  = "notBreaching"

  metric_name = "GlueDatabaseCount"
  namespace   = "EMDS/Glue"
  period      = 300
  statistic   = "Maximum"

  dimensions = {
    Environment = local.environment_shorthand
  }

  alarm_actions = [
    aws_sns_topic.emds_alerts.arn
  ]
}

resource "aws_cloudwatch_log_metric_filter" "mdss_fatal_failures" {
  name           = "mdss-fatal-failures"
  log_group_name = "/aws/lambda/load_mdss"

  pattern = "{ ($.level = \"ERROR\") || ($.message = \"*Pipeline execution failed*\") || ($.message = \"*LoadClientJobFailed*\") || ($.message = \"*DatabaseTerminalException*\") || ($.message = \"*Terminal exception*\") }"

  metric_transformation {
    name      = "FatalFailures"
    namespace = "EMDS/MDSS"
    value     = "1"
  }
}
