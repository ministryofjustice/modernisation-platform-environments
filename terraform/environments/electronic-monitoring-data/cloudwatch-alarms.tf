data "aws_sqs_queue" "load_mdss_dlq" {
  count = local.is-development ? 0 : 1
  name  = "load_mdss-dlq"
}

resource "aws_cloudwatch_metric_alarm" "load_mdss_dlq_alarm" {
  count = local.is-development ? 0 : 1

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
    QueueName = data.aws_sqs_queue.load_mdss_dlq[0].name
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
    QueueName = aws_sqs_queue.clean_mdss_load_dlq.name
  }

  alarm_actions = [
    aws_sns_topic.emds_alerts.arn
  ]
}

resource "aws_cloudwatch_metric_alarm" "glue_database_count_high" {
  count = local.is-development ? 0 : 1

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

#maybe disable this for now
resource "aws_cloudwatch_metric_alarm" "load_mdss_lambda_errors" {
  count = local.is-development ? 0 : 1

  alarm_name          = "load_mdss_lambda_errors"
  alarm_description   = "Triggered when load_mdss lambda reports any errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 0
  treat_missing_data  = "notBreaching"

  metric_name = "Errors"
  namespace   = "AWS/Lambda"
  period      = 60
  statistic   = "Sum"

  dimensions = {
    FunctionName = "load_mdss"
  }

  alarm_actions = [aws_sns_topic.emds_alerts.arn]
}
