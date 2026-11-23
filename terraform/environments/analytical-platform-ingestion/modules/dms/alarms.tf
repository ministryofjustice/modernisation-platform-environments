# Alarm names must start with "${var.db}-" so aws_cloudwatch_event_rule.dms_alarms forwards them to Slack

locals {
  lambda_error_alarms = {
    validation         = module.validation_lambda_function.lambda_function_name
    metadata-generator = module.metadata_generator.lambda_function_name
  }

  # DMS writes task logs to a log group it creates and names after the replication instance
  dms_task_log_group = "dms-tasks-${var.dms_replication_instance.replication_instance_id}"

  dms_task_log_filters = {
    errors = {
      pattern     = "\"]E:\""
      description = "DMS task log for ${var.db} contains errors (]E:). Check log group ${local.dms_task_log_group}."
    }
    truncation = {
      pattern     = "\"Truncation\""
      description = "DMS task for ${var.db} truncated column values (LOB larger than LobMaxSize). Data is incomplete; check log group ${local.dms_task_log_group}."
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  for_each = local.lambda_error_alarms

  alarm_name          = "${var.db}-${each.key}-lambda-errors"
  alarm_description   = "${each.value} Lambda failed. Check log group /aws/lambda/${each.value}."
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = each.value
  }

  tags = var.tags
}

resource "aws_cloudwatch_log_metric_filter" "dms_task_logs" {
  for_each = local.dms_task_log_filters

  name           = "${var.db}-dms-task-log-${each.key}"
  log_group_name = local.dms_task_log_group
  pattern        = each.value.pattern

  metric_transformation {
    name      = "${var.db}-dms-task-log-${each.key}"
    namespace = "DMSTaskLogs"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "dms_task_logs" {
  for_each = local.dms_task_log_filters

  alarm_name          = "${var.db}-dms-task-log-${each.key}"
  alarm_description   = each.value.description
  namespace           = "DMSTaskLogs"
  metric_name         = aws_cloudwatch_log_metric_filter.dms_task_logs[each.key].metric_transformation[0].name
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "replication_instance_memory" {
  alarm_name          = "${var.db}-dms-instance-low-memory"
  alarm_description   = "DMS replication instance ${var.dms_replication_instance.replication_instance_id} is low on memory; the task may be killed (out of memory)."
  namespace           = "AWS/DMS"
  metric_name         = "FreeableMemory"
  statistic           = "Minimum"
  period              = 300
  evaluation_periods  = 1
  threshold           = var.replication_instance_freeable_memory_threshold_bytes
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ReplicationInstanceIdentifier = var.dms_replication_instance.replication_instance_id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "replication_instance_cpu" {
  alarm_name          = "${var.db}-dms-instance-high-cpu"
  alarm_description   = "DMS replication instance ${var.dms_replication_instance.replication_instance_id} CPU has been above ${var.replication_instance_cpu_threshold_percent}% for 15 minutes."
  namespace           = "AWS/DMS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 3
  threshold           = var.replication_instance_cpu_threshold_percent
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ReplicationInstanceIdentifier = var.dms_replication_instance.replication_instance_id
  }

  tags = var.tags
}

# Dev-only end-to-end alert test: an unreadable "parquet" file makes the validation Lambda fail it and alert
resource "aws_s3_object" "alert_test" {
  count = var.environment == "development" && var.alert_test_run != "" ? 1 : 0

  bucket  = aws_s3_bucket.landing.bucket
  key     = "${var.dms_target_prefix}/alert_test/LOAD00000001.parquet"
  content = "DMS alerting test file, not a valid parquet file (run ${var.alert_test_run})"
}
