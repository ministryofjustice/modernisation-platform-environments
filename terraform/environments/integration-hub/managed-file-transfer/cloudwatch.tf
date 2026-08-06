locals {
  cloudwatch_alarm_actions_high_priority = [module.sns_cloudwatch_alarms_high_priority.topic_arn]
  cloudwatch_alarm_actions_low_priority  = [module.sns_cloudwatch_alarms_low_priority.topic_arn]

  cloudwatch_lambda_alarms = {
    "custom-idp" = {
      alarm_name_prefix           = "${local.application_name}-${local.component_name}-custom-idp"
      description                 = "AWS Transfer custom IdP Lambda"
      function_name               = module.lambda_custom_idp.lambda_function_name
      duration_threshold_ms       = 25000
      duration_evaluation_periods = 2
    }
    "unscanned-to-processing" = {
      alarm_name_prefix           = "${local.application_name}-unscanned-to-processing"
      description                 = "Unscanned to processing file mover Lambda"
      function_name               = module.lambda_unscanned_to_processing.lambda_function_name
      duration_threshold_ms       = 25000
      duration_evaluation_periods = 2
    }
    "processing-to-post-scan" = {
      alarm_name_prefix           = "${local.application_name}-processing-to-post-scan"
      description                 = "Processing to post-scan file mover Lambda"
      function_name               = module.lambda_processing_to_post_scan.lambda_function_name
      duration_threshold_ms       = 25000
      duration_evaluation_periods = 2
    }
    "clean-file-presigned-url-notifier" = {
      alarm_name_prefix           = "${local.application_name}-clean-file-presigned-url-notifier"
      description                 = "Clean file presigned URL notifier Lambda"
      function_name               = module.proof_of_concept_notification.lambda_clean_file_presigned_url_notifier.lambda_function_name
      duration_threshold_ms       = 2500
      duration_evaluation_periods = 2
    }
  }

  cloudwatch_sqs_main_queue_alarms = {
    "unscanned-s3-notifications" = {
      alarm_name_prefix                    = "${local.application_name}-unscanned-s3-notifications"
      description                          = "Unscanned S3 notification queue"
      queue_name                           = module.sqs_unscanned_s3_notifications.queue_name
      oldest_message_threshold_seconds     = 900
      visible_messages_threshold           = 100
      visible_messages_evaluation_periods  = 3
      visible_messages_datapoints_to_alarm = 3
    }
    "guard-duty-malware-protection-for-s3-events" = {
      alarm_name_prefix                    = "${local.application_name}-guard-duty-malware-protection-for-s3-events"
      description                          = "GuardDuty Malware Protection for S3 event queue"
      queue_name                           = module.sqs_guard_duty_malware_protection_for_s3_events.queue_name
      oldest_message_threshold_seconds     = 900
      visible_messages_threshold           = 100
      visible_messages_evaluation_periods  = 3
      visible_messages_datapoints_to_alarm = 3
    }
    "clean-file-notifications" = {
      alarm_name_prefix                    = "${local.application_name}-clean-file-notifications"
      description                          = "Clean file notification queue"
      queue_name                           = module.proof_of_concept_notification.sqs_clean_file_notifications.queue_name
      oldest_message_threshold_seconds     = 900
      visible_messages_threshold           = 100
      visible_messages_evaluation_periods  = 3
      visible_messages_datapoints_to_alarm = 3
    }
  }

  cloudwatch_sqs_dlq_alarms = {
    "unscanned-s3-notifications-dlq" = {
      alarm_name_prefix = "${local.application_name}-unscanned-s3-notifications-dlq"
      description       = "Unscanned S3 notification dead-letter queue"
      queue_name        = module.sqs_unscanned_s3_notifications.dead_letter_queue_name
    }
    "guard-duty-malware-protection-for-s3-events-dlq" = {
      alarm_name_prefix = "${local.application_name}-guard-duty-malware-protection-for-s3-events-dlq"
      description       = "GuardDuty Malware Protection for S3 event dead-letter queue"
      queue_name        = module.sqs_guard_duty_malware_protection_for_s3_events.dead_letter_queue_name
    }
    "clean-file-notifications-dlq" = {
      alarm_name_prefix = "${local.application_name}-clean-file-notifications-dlq"
      description       = "Clean file notification dead-letter queue"
      queue_name        = module.proof_of_concept_notification.sqs_clean_file_notifications.dead_letter_queue_name
    }
  }

  cloudwatch_guardduty_malware_protection_dimensions = {
    "Malware Protection Plan Id" = aws_guardduty_malware_protection_plan.this.id
    "Resource Name"              = module.s3_bucket["processing"].s3_bucket_id
  }

  cloudwatch_query_definitions = {
    "transfer-authentication-failures" = {
      log_group_names = [module.cloudwatch_transfer.cloudwatch_log_group_name]
      query_string    = <<-QUERY
        fields @timestamp, `activity-type`, user, method, `source-ip`, message, `session-id`
        | filter `activity-type` = "AUTH_FAILURE"
        | sort @timestamp desc
        | limit 100
      QUERY
    }
    "custom-idp-authentication-failures" = {
      log_group_names = [module.lambda_custom_idp.lambda_cloudwatch_log_group_name]
      query_string    = <<-QUERY
        fields @timestamp, @message
        | filter @message like /Authentication failed:|Unexpected custom IdP error/
        | sort @timestamp desc
        | limit 100
      QUERY
    }
    "lambda-file-movement-failures" = {
      log_group_names = [
        module.lambda_unscanned_to_processing.lambda_cloudwatch_log_group_name,
        module.lambda_processing_to_post_scan.lambda_cloudwatch_log_group_name,
      ]
      query_string = <<-QUERY
        fields @timestamp, level, location, message, object_key, source_bucket_name, destination_bucket_name, scan_result_status
        | filter level = "ERROR"
        | sort @timestamp desc
        | limit 100
      QUERY
    }
    "clean-file-notification-failures" = {
      log_group_names = [module.proof_of_concept_notification.lambda_clean_file_presigned_url_notifier.lambda_cloudwatch_log_group_name]
      query_string    = <<-QUERY
        fields @timestamp, level, location, message, bucket_name, object_key, version_id
        | filter level = "ERROR"
        | sort @timestamp desc
        | limit 100
      QUERY
    }
  }
}

module "cloudwatch_transfer" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "5.7.2"

  name              = "/aws/transfer/${local.application_name}-${local.component_name}"
  kms_key_id        = module.kms_cloudwatch_logs.key_arn
  retention_in_days = 30

  tags = local.tags
}

module "cloudwatch_lambda_errors" {
  for_each = local.cloudwatch_lambda_alarms

  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.7.2"

  alarm_name          = "${each.value.alarm_name_prefix}-errors"
  alarm_description   = "${each.value.description} errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.cloudwatch_alarm_actions_high_priority
  ok_actions          = local.cloudwatch_alarm_actions_high_priority

  dimensions = {
    FunctionName = each.value.function_name
  }

  tags = local.tags
}

module "cloudwatch_lambda_throttles" {
  for_each = local.cloudwatch_lambda_alarms

  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.7.2"

  alarm_name          = "${each.value.alarm_name_prefix}-throttles"
  alarm_description   = "${each.value.description} throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.cloudwatch_alarm_actions_high_priority
  ok_actions          = local.cloudwatch_alarm_actions_high_priority

  dimensions = {
    FunctionName = each.value.function_name
  }

  tags = local.tags
}

module "cloudwatch_lambda_duration" {
  for_each = local.cloudwatch_lambda_alarms

  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.7.2"

  alarm_name          = "${each.value.alarm_name_prefix}-duration"
  alarm_description   = "${each.value.description} duration is approaching timeout"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = each.value.duration_evaluation_periods
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Average"
  threshold           = each.value.duration_threshold_ms
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.cloudwatch_alarm_actions_low_priority
  ok_actions          = local.cloudwatch_alarm_actions_low_priority

  dimensions = {
    FunctionName = each.value.function_name
  }

  tags = local.tags
}

module "cloudwatch_sqs_oldest_message_age" {
  for_each = local.cloudwatch_sqs_main_queue_alarms

  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.7.2"

  alarm_name          = "${each.value.alarm_name_prefix}-oldest-message-age"
  alarm_description   = "${each.value.description} has messages older than expected"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Maximum"
  threshold           = each.value.oldest_message_threshold_seconds
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.cloudwatch_alarm_actions_low_priority
  ok_actions          = local.cloudwatch_alarm_actions_low_priority

  dimensions = {
    QueueName = each.value.queue_name
  }

  tags = local.tags
}

module "cloudwatch_sqs_visible_messages" {
  for_each = local.cloudwatch_sqs_main_queue_alarms

  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.7.2"

  alarm_name          = "${each.value.alarm_name_prefix}-visible-messages"
  alarm_description   = "${each.value.description} backlog is higher than expected"
  comparison_operator = "GreaterThanThreshold"
  datapoints_to_alarm = each.value.visible_messages_datapoints_to_alarm
  evaluation_periods  = each.value.visible_messages_evaluation_periods
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Maximum"
  threshold           = each.value.visible_messages_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.cloudwatch_alarm_actions_low_priority
  ok_actions          = local.cloudwatch_alarm_actions_low_priority

  dimensions = {
    QueueName = each.value.queue_name
  }

  tags = local.tags
}

module "cloudwatch_sqs_dlq_visible_messages" {
  for_each = local.cloudwatch_sqs_dlq_alarms

  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.7.2"

  alarm_name          = "${each.value.alarm_name_prefix}-visible-messages"
  alarm_description   = "${each.value.description} contains failed messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Maximum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.cloudwatch_alarm_actions_high_priority
  ok_actions          = local.cloudwatch_alarm_actions_high_priority

  dimensions = {
    QueueName = each.value.queue_name
  }

  tags = local.tags
}

module "cloudwatch_guardduty_failed_scans" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.7.2"

  alarm_name          = "${local.application_name}-guardduty-failed-scans"
  alarm_description   = "GuardDuty Malware Protection for S3 failed to scan one or more objects"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FailedScanCount"
  namespace           = "AWS/GuardDuty/MalwareProtection"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.cloudwatch_alarm_actions_high_priority
  ok_actions          = local.cloudwatch_alarm_actions_high_priority
  dimensions          = local.cloudwatch_guardduty_malware_protection_dimensions

  tags = local.tags
}

module "cloudwatch_guardduty_infected_scans" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.7.2"

  alarm_name          = "${local.application_name}-guardduty-infected-scans"
  alarm_description   = "GuardDuty Malware Protection for S3 found a potentially malicious object"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "InfectedScanCount"
  namespace           = "AWS/GuardDuty/MalwareProtection"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.cloudwatch_alarm_actions_high_priority
  ok_actions          = local.cloudwatch_alarm_actions_high_priority
  dimensions          = local.cloudwatch_guardduty_malware_protection_dimensions

  tags = local.tags
}

module "cloudwatch_guardduty_skipped_scans" {
  for_each = {
    unsupported           = "Unsupported"
    "missing-permissions" = "MissingPermissions"
  }

  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.7.2"

  alarm_name          = "${local.application_name}-guardduty-skipped-scans-${each.key}"
  alarm_description   = "GuardDuty Malware Protection for S3 skipped one or more objects due to ${each.value}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "SkippedScanCount"
  namespace           = "AWS/GuardDuty/MalwareProtection"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.cloudwatch_alarm_actions_high_priority
  ok_actions          = local.cloudwatch_alarm_actions_high_priority
  dimensions = merge(local.cloudwatch_guardduty_malware_protection_dimensions, {
    "Skipped Reason" = each.value
  })

  tags = local.tags
}

module "cloudwatch_transfer_files_in" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "5.7.2"

  alarm_name          = "${local.application_name}-${local.component_name}-transfer-files-in-spike"
  alarm_description   = "AWS Transfer Family file ingress is higher than expected for the MVP"
  comparison_operator = "GreaterThanThreshold"
  datapoints_to_alarm = 5
  evaluation_periods  = 10
  metric_name         = "FilesIn"
  namespace           = "AWS/Transfer"
  period              = 60
  statistic           = "Sum"
  threshold           = 1000
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.cloudwatch_alarm_actions_low_priority
  ok_actions          = local.cloudwatch_alarm_actions_low_priority

  dimensions = {
    ServerId = aws_transfer_server.this.id
  }

  tags = local.tags
}

module "cloudwatch_query_definitions" {
  for_each = local.cloudwatch_query_definitions

  source  = "terraform-aws-modules/cloudwatch/aws//modules/query-definition"
  version = "5.7.2"

  name            = "${local.application_name}/${local.component_name}/${each.key}"
  log_group_names = each.value.log_group_names
  query_string    = each.value.query_string
}
