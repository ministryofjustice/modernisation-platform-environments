# ------------------------------------------------------------------------------
# Incident-threaded Slack notifications for CloudWatch alarms
#
# - Triggered by EventBridge "CloudWatch Alarm State Change"
# - Uses S3 as state store:
#   alarm-threading/current/<env>/<alarm_name>.json
# - Publishes Amazon Q custom notifications to the existing emds_alerts SNS topic
# - Starts the staged DB janitor Step Functions workflow only for the
#   glue_database_count_high alarm
# ------------------------------------------------------------------------------

locals {
  # State bucket for incident-threading state
  # Use the environment's logging bucket created by this stack
  alarm_thread_state_bucket = module.s3-logging-bucket.bucket.id

  alarm_thread_state_prefix = "alarm-threading/current"

  alarm_debounce_seconds = 120

  alarm_debounce_bypass_names = concat(
    [
      aws_cloudwatch_metric_alarm.glue_database_count_high.alarm_name,
      aws_cloudwatch_metric_alarm.fms_audit_write_failed.alarm_name,
    ],
    [
      for _, alarm in aws_cloudwatch_metric_alarm.sqs_dlq_has_messages :
      alarm.alarm_name
    ],
    [
      for _, alarm in aws_cloudwatch_metric_alarm.merge_lambda_dlq_has_messages :
      alarm.alarm_name
    ],
    [
      for _, alarm in aws_cloudwatch_metric_alarm.specials_guard_detected :
      alarm.alarm_name
    ],
    [
      for _, alarm in aws_cloudwatch_metric_alarm.specials_guard_cleanup_failed :
      alarm.alarm_name
    ],
  )
}

# ------------------------------------------------------------------------------
# EventBridge: CloudWatch alarm state changes -> Lambda
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "alarm_state_change_threader" {
  name = "emds-alarm-state-change-threader-${local.environment_shorthand}"

  description = "Routes CloudWatch ALARM/OK state changes to cloudwatch_alarm_threader for incident-threaded Slack notifications"

  event_pattern = jsonencode(
    {
      "source" : ["aws.cloudwatch"],
      "detail-type" : ["CloudWatch Alarm State Change"],
      "detail" : {
        "alarmName" : concat(
          [
            aws_cloudwatch_metric_alarm.glue_database_count_high.alarm_name,
            aws_cloudwatch_metric_alarm.mdss_reconciler_errors_alarm[0].alarm_name,
            aws_cloudwatch_metric_alarm.fms_audit_write_failed.alarm_name
          ],
          [
            for _, alarm in aws_cloudwatch_metric_alarm.sqs_dlq_has_messages :
            alarm.alarm_name
          ],
          [
            for _, alarm in aws_cloudwatch_metric_alarm.merge_lambda_dlq_has_messages :
            alarm.alarm_name
          ],
          [
            for _, alarm in aws_cloudwatch_metric_alarm.merge_lambdas_queries_failing :
            alarm.alarm_name
          ],
          [
            for _, alarm in aws_cloudwatch_metric_alarm.merge_lambdas_excessive_scanning :
            alarm.alarm_name
          ],
          [
            for _, alarm in aws_cloudwatch_metric_alarm.merge_lambdas_slow_execution :
            alarm.alarm_name
          ],
          [
            for _, alarm in aws_cloudwatch_metric_alarm.merge_lambdas_long_queue :
            alarm.alarm_name
          ],
          [
            for _, alarm in aws_cloudwatch_metric_alarm.specials_guard_detected :
            alarm.alarm_name
          ],
          [
            for _, alarm in aws_cloudwatch_metric_alarm.specials_guard_cleanup_failed :
            alarm.alarm_name
          ],
          [
            for _, alarm in aws_cloudwatch_metric_alarm.specials_guard_heartbeat_missing :
            alarm.alarm_name
          ],
          [
            for alarm in aws_cloudwatch_metric_alarm.specials_guard_lambda_errors :
            alarm.alarm_name
          ],
        )
      }
    }
  )
}

resource "aws_cloudwatch_event_target" "alarm_state_change_threader" {
  rule = aws_cloudwatch_event_rule.alarm_state_change_threader.name
  arn  = module.cloudwatch_alarm_threader.lambda_function_arn
}

resource "aws_lambda_permission" "alarm_state_change_threader_allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridgeAlarmStateChange"
  action        = "lambda:InvokeFunction"
  function_name = module.cloudwatch_alarm_threader.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.alarm_state_change_threader.arn
}

# ------------------------------------------------------------------------------
# Transient alarm suppression metric
# Track alarms that recovered before human notification was required.
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_log_metric_filter" "alarm_transient_suppressed" {
  name           = "cloudwatch-alarm-transient-suppressed"
  log_group_name = module.cloudwatch_alarm_threader.cloudwatch_log_group.name
  pattern        = "{ $.message.event = \"CW_ALARM_TRANSIENT_SUPPRESSED\" }"

  metric_transformation {
    name      = "TransientAlarmSuppressedCount"
    namespace = "EMDS/CloudWatch"
    value     = "1"
  }
}
