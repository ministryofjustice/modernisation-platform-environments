# ------------------------------------------------------------------------------
# Incident-threaded Slack notifications for CloudWatch alarms (Amazon Q/Chatbot)
#
# - Triggered by EventBridge "CloudWatch Alarm State Change"
# - Uses S3 as state store: alarm-threading/current/<env>/<alarm_name>.json
# - Publishes Amazon Q custom notifications to the existing emds_alerts SNS topic
# ------------------------------------------------------------------------------

locals {
  # State bucket per environment (logs buckets)
  alarm_thread_state_bucket = {
    dev     = "emds-dev-bucket-logs-20240917140510319000000006"
    test    = "emds-test-bucket-logs-2024092309592738660000000b"
    preprod = "emds-preprod-bucket-logs-2024110511092940930000000a"
    prod    = "emds-prod-bucket-logs-20240918073115961600000004"
  }[local.environment_shorthand]

  alarm_thread_state_prefix = "alarm-threading/current"
}

# ------------------------------------------------------------------------------
# EventBridge: CloudWatch alarm state changes -> Lambda
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "alarm_state_change_threader" {
  name        = "emds-alarm-state-change-threader-${local.environment_shorthand}"
  description = "Routes CloudWatch ALARM/OK state changes to cloudwatch_alarm_threader for incident-threaded Slack notifications"

  event_pattern = jsonencode({
    "source": ["aws.cloudwatch"],
    "detail-type": ["CloudWatch Alarm State Change"],
    "detail": {
      "alarmName": [
        aws_cloudwatch_metric_alarm.load_mdss_dlq_alarm.alarm_name,
        aws_cloudwatch_metric_alarm.clean_dlt_dlq_alarm.alarm_name,
        aws_cloudwatch_metric_alarm.glue_database_count_high.alarm_name
      ]
    }
  })
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
