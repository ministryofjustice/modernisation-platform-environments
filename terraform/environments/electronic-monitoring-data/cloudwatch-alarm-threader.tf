# ------------------------------------------------------------------------------
# Incident-threaded Slack notifications for CloudWatch alarms
#
# - Triggered by EventBridge CloudWatch alarm state-change events
# - Uses S3 for incident-threading state
# - Publishes custom notifications through the existing emds_alerts topic
# - Starts the staged DB janitor only for the Glue database-count alarm
# ------------------------------------------------------------------------------

locals {
  alarm_thread_state_bucket = module.s3-logging-bucket.bucket.id

  alarm_thread_state_prefix = "alarm-threading/current"
}


# ------------------------------------------------------------------------------
# CloudWatch alarm state changes -> alarm threader Lambda
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "alarm_state_change_threader" {
  name = format(
    "emds-alarm-state-change-threader-%s",
    local.environment_shorthand,
  )

  description = "Routes CloudWatch ALARM and OK state changes to the incident-threaded Slack notification Lambda"

  event_pattern = jsonencode({
    source = [
      "aws.cloudwatch",
    ]

    detail-type = [
      "CloudWatch Alarm State Change",
    ]

    detail = {
      alarmName = concat(
        [
          aws_cloudwatch_metric_alarm.glue_database_count_high.alarm_name,
          aws_cloudwatch_metric_alarm.mdss_reconciler_errors_alarm[0].alarm_name,
        ],
        [
          for _, alarm in aws_cloudwatch_metric_alarm.sqs_dlq_has_messages :
          alarm.alarm_name
        ],
        [
          for _, alarm in aws_cloudwatch_metric_alarm.serco_fms_key_distribution_errors :
          alarm.alarm_name
        ],
      )
    }
  })
}

resource "aws_cloudwatch_event_target" "alarm_state_change_threader" {
  rule = aws_cloudwatch_event_rule.alarm_state_change_threader.name

  arn = module.cloudwatch_alarm_threader.lambda_function_arn
}

resource "aws_lambda_permission" "alarm_state_change_threader_allow_eventbridge" {
  statement_id = "AllowExecutionFromEventBridgeAlarmStateChange"

  action = "lambda:InvokeFunction"

  function_name = module.cloudwatch_alarm_threader.lambda_function_name

  principal = "events.amazonaws.com"

  source_arn = aws_cloudwatch_event_rule.alarm_state_change_threader.arn
}