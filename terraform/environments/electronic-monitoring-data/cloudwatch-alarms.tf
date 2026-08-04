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
  merge_lambdas = {
    staged_position = {
      lambda_name = module.merge_mdss_staged_position[0].lambda_function_name
      threshold   = 1000000000
    }
    staged_event = {
      lambda_name = module.merge_mdss_staged_event[0].lambda_function_name
      threshold   = 1000000000
    }
    ac_position = {
      lambda_name = module.merge_ac_position[0].lambda_function_name
      threshold   = 1000000000
    }
    emdi_position = {
      lambda_name = module.merge_emdi_position[0].lambda_function_name
      threshold   = 1000000000
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

  metric_query {
    id          = "visible"
    return_data = false

    metric {
      metric_name = "ApproximateNumberOfMessagesVisible"
      namespace   = "AWS/SQS"
      period      = 60
      stat        = "Sum"

      dimensions = {
        QueueName = each.value.queue_name
      }
    }
  }

  metric_query {
    id          = "not_visible"
    return_data = false

    metric {
      metric_name = "ApproximateNumberOfMessagesNotVisible"
      namespace   = "AWS/SQS"
      period      = 60
      stat        = "Sum"

      dimensions = {
        QueueName = each.value.queue_name
      }
    }
  }

  metric_query {
    id          = "total_messages"
    expression  = "visible + not_visible"
    label       = "Messages visible or in flight"
    return_data = true
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
    FunctionName = module.mdss_load_redrive_controller[0].lambda_function_name
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

################
# Merge Lambdas
################

resource "aws_cloudwatch_metric_alarm" "none_succeeded" {
  for_each = local.merge_lambdas

  alarm_name          = "none_succeeded_${each.key}"
  alarm_description   = "Detects no queries completed across 15 minutes."
  comparison_operator = "LessThanOrEqualToThreshold"
  threshold           = 0
  evaluation_periods  = 1
  treat_missing_data  = "notBreaching"

  actions_enabled = false

  metric_query {
    id          = "total"
    expression  = "succeeded + failed"
    label       = "Combined total"
    return_data = true
  }

  metric_query {
    id          = "succeeded"
    return_data = false

    metric {
      namespace   = "EM/MergeLambdas"
      metric_name = "SucceededQueries"
      period      = 900
      stat        = "Sum"

      dimensions = {
        FunctionName = each.value.lambda_name
      }
    }
  }

  metric_query {
    id          = "failed"
    return_data = false

    metric {
      namespace   = "EM/MergeLambdas"
      metric_name = "FailedQueries"
      period      = 900
      stat        = "Sum"

      dimensions = {
        FunctionName = each.value.lambda_name
      }
    }
  }

  alarm_actions = [
    aws_sns_topic.emds_alerts.arn
  ]
}


resource "aws_cloudwatch_metric_alarm" "queries_failing" {
  for_each = local.merge_lambdas

  alarm_name          = "queries_failing_${each.key}"
  alarm_description   = "Detects 3 failed queries within 15 minutes."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 3
  period              = 900
  statistic           = "Sum"
  evaluation_periods  = 1
  treat_missing_data  = "notBreaching"

  actions_enabled = false

  metric_name = "FailedQueries"
  namespace   = "EM/MergeLambdas"

  dimensions = {
    FunctionName = each.value.lambda_name
  }

  alarm_actions = [
    aws_sns_topic.emds_alerts.arn
  ]
}

resource "aws_cloudwatch_metric_alarm" "excessive_scanning" {
  for_each = local.merge_lambdas

  alarm_name          = "excessive_scanning_${each.key}"
  alarm_description   = "Detects when average scan across an hour is excessive."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = each.value.threshold
  unit                = "Bytes"
  period              = 3600
  statistic           = "Average"
  evaluation_periods  = 1
  treat_missing_data  = "notBreaching"

  actions_enabled = false

  metric_name = "DataScanned"
  namespace   = "EM/MergeLambdas"

  dimensions = {
    FunctionName = each.value.lambda_name
  }

  alarm_actions = [
    aws_sns_topic.emds_alerts.arn
  ]
}

resource "aws_cloudwatch_metric_alarm" "slow_execution" {
  for_each = local.merge_lambdas

  alarm_name          = "slow_execution_${each.key}"
  alarm_description   = "Detects when average run time over half an hour is slow."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 120000
  unit                = "Milliseconds"
  period              = 1800
  statistic           = "Average"
  evaluation_periods  = 1
  treat_missing_data  = "notBreaching"

  actions_enabled = false

  metric_name = "TotalExecutionTime"
  namespace   = "EM/MergeLambdas"

  dimensions = {
    FunctionName = each.value.lambda_name
  }

  alarm_actions = [
    aws_sns_topic.emds_alerts.arn
  ]
}

resource "aws_cloudwatch_metric_alarm" "long_queue" {
  for_each = local.merge_lambdas

  alarm_name          = "long_queue_${each.key}"
  alarm_description   = "Detects when average queue time over 15 minutes is slow."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 60000
  unit                = "Milliseconds"
  period              = 900
  statistic           = "Average"
  evaluation_periods  = 1
  treat_missing_data  = "notBreaching"

  actions_enabled = false

  metric_name = "QueryQueueTime"
  namespace   = "EM/MergeLambdas"

  dimensions = {
    FunctionName = each.value.lambda_name
  }

  alarm_actions = [
    aws_sns_topic.emds_alerts.arn
  ]
}