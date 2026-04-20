locals {
  sqs_dlq_alarm_queues = {
    load_mdss_dlq = {
      queue_name        = module.load_mdss_event_queue.sqs_dlq.name
      alarm_name        = "load_mdss_dlq_has_messages"
      alarm_description = "Triggered when Load MDSS DLQ contains messages"
    }

    clean_dlt_dlq = {
      queue_name        = aws_sqs_queue.clean_dlt_load_dlq.name
      alarm_name        = "clean_dlt_dlq_has_messages"
      alarm_description = "Triggered when cleanup dlt DLQ receives failures"
    }

    load_fms_dlq = {
      queue_name = module.load_fms_event_queue.sqs_dlq.name
    }

    process_landing_bucket_files_fms_general_dlq = {
      queue_name = local.live_feed_dlq_names.process_landing_bucket_files_fms_general
    }

    process_landing_bucket_files_fms_ho_dlq = {
      queue_name = local.live_feed_dlq_names.process_landing_bucket_files_fms_ho
    }

    process_landing_bucket_files_fms_specials_dlq = {
      queue_name = local.live_feed_dlq_names.process_landing_bucket_files_fms_specials
    }

    process_landing_bucket_files_mdss_general_dlq = {
      queue_name = local.live_feed_dlq_names.process_landing_bucket_files_mdss_general
    }

    process_landing_bucket_files_mdss_ho_dlq = {
      queue_name = local.live_feed_dlq_names.process_landing_bucket_files_mdss_ho
    }

    process_landing_bucket_files_mdss_specials_dlq = {
      queue_name = local.live_feed_dlq_names.process_landing_bucket_files_mdss_specials
    }

    scan_dlq = {
      queue_name = local.live_feed_dlq_names.scan
    }

    process_fms_metadata_dlq = {
      queue_name = local.live_feed_dlq_names.process_fms_metadata
    }

    format_fms_json_dlq = {
      queue_name = aws_sqs_queue.format_fms_json_event_dlq.name
    }

    push_data_export_to_p1_dlq = {
      queue_name = local.live_feed_dlq_names.push_data_export_to_p1
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "sqs_dlq_has_messages" {
  for_each = local.sqs_dlq_alarm_queues

  alarm_name = try(
    each.value.alarm_name,
    "${replace(each.value.queue_name, "-", "_")}_has_messages"
  )

  alarm_description = try(
    each.value.alarm_description,
    "Triggered when ${each.value.queue_name} contains messages"
  )

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
    QueueName = each.value.queue_name
  }

  alarm_actions = [
    aws_sns_topic.emds_alerts.arn
  ]
}

resource "aws_cloudwatch_metric_alarm" "mdss_reconciler_errors_alarm" {
  count               = 1
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