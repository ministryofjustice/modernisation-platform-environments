resource "aws_cloudwatch_metric_alarm" "load_mdss_dlq_alarm" {
  alarm_name          = "load_mdss_dlq_has_messages"
  alarm_description   = "Triggered when Load MDSS DLQ contains messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 0
  treat_missing_data  = "notBreaching"

  # We use EventBridge -> cloudwatch_alarm_threader -> SNS custom notifications.
  # Disable default alarm actions to avoid duplicate Slack messages.
  actions_enabled = false

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

resource "aws_cloudwatch_metric_alarm" "clean_dlt_dlq_alarm" {
  alarm_name          = "clean_dlt_dlq_has_messages"
  alarm_description   = "Triggered when cleanup dlt DLQ receives failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 0
  treat_missing_data  = "notBreaching"

  actions_enabled = false

  metric_name = "ApproximateNumberOfMessagesVisible"
  namespace   = "AWS/SQS"
  period      = 60
  statistic   = "Sum"

  dimensions = {
    QueueName = aws_sqs_queue.clean_dlt_load_dlq.name
  }

  alarm_actions = [
    aws_sns_topic.emds_alerts.arn
  ]
}

resource "aws_cloudwatch_metric_alarm" "mdss_reconciler_errors_alarm" {
  count               = local.is-preproduction || local.is-production ? 0 : 1
  alarm_name          = "mdss_reconciler_errors"
  alarm_description   = "Triggered when the mdss_reconciler Lambda records errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 0
  treat_missing_data  = "notBreaching"

  actions_enabled = false

  metric_name = "Errors"
  namespace   = "AWS/Lambda"
  period      = 60
  statistic   = "Sum"

  dimensions = {
    FunctionName = module.mdss_reconciler[0].lambda_function_name
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

  actions_enabled = false

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

# ------------------------------------------------------------------------------
# FMS DLQ alarms routed to Slack via EventBridge -> cloudwatch_alarm_threader
# ------------------------------------------------------------------------------

locals {
  additional_dlq_alarm_queue_names = toset([
    "load_fms-dlq",

    "process_landing_bucket_files_fms_general-dlq",
    "process_landing_bucket_files_fms_ho-dlq",
    "process_landing_bucket_files_fms_specials-dlq",

    "process_landing_bucket_files_mdss_general-dlq",
    "process_landing_bucket_files_mdss_ho-dlq",
    "process_landing_bucket_files_mdss_specials-dlq",

    "scan-dlq",
    "process_fms_metadata-dlq",
    "format-fms-json-dlq",
    "push_data_export_to_p1-dlq",
  ])
}

resource "aws_cloudwatch_metric_alarm" "additional_dlq_has_messages" {
  for_each = local.additional_dlq_alarm_queue_names

  alarm_name          = "${replace(each.value, "-", "_")}_has_messages"
  alarm_description   = "Triggered when ${each.value} contains messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 0
  treat_missing_data  = "notBreaching"

  # Use EventBridge -> cloudwatch_alarm_threader -> SNS custom notifications.
  # Disable direct alarm actions to avoid duplicate Slack messages.
  actions_enabled = false

  metric_name = "ApproximateNumberOfMessagesVisible"
  namespace   = "AWS/SQS"
  period      = 60
  statistic   = "Sum"

  dimensions = {
    QueueName = each.value
  }

  alarm_actions = [
    aws_sns_topic.emds_alerts.arn
  ]
}