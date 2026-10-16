# ------------------------------------------------------------------------------
# Live-feed operations dashboard
# Show alarm state, suppressed transients, and queue age in one place.
# ------------------------------------------------------------------------------

locals {
  live_feed_operational_alarm_arns = concat(
    [
      aws_cloudwatch_metric_alarm.glue_database_count_high.arn,
      aws_cloudwatch_metric_alarm.fms_audit_write_failed.arn,
      aws_cloudwatch_metric_alarm.live_feed_incident_events_dlq.arn,
      aws_cloudwatch_metric_alarm.cloudwatch_alarm_debounce_dlq.arn,
    ],
    [
      for alarm in aws_cloudwatch_metric_alarm.mdss_reconciler_errors_alarm :
      alarm.arn
    ],
    [
      for _, alarm in aws_cloudwatch_metric_alarm.sqs_dlq_has_messages :
      alarm.arn
    ],
    [
      for _, alarm in aws_cloudwatch_metric_alarm.merge_lambda_dlq_has_messages :
      alarm.arn
    ],
    [
      for _, alarm in aws_cloudwatch_metric_alarm.merge_lambdas_queries_failing :
      alarm.arn
    ],
    [
      for _, alarm in aws_cloudwatch_metric_alarm.merge_lambdas_excessive_scanning :
      alarm.arn
    ],
    [
      for _, alarm in aws_cloudwatch_metric_alarm.merge_lambdas_slow_execution :
      alarm.arn
    ],
    [
      for _, alarm in aws_cloudwatch_metric_alarm.merge_lambdas_long_queue :
      alarm.arn
    ],
    [
      for _, alarm in aws_cloudwatch_metric_alarm.specials_guard_detected :
      alarm.arn
    ],
    [
      for _, alarm in aws_cloudwatch_metric_alarm.specials_guard_cleanup_failed :
      alarm.arn
    ],
    [
      for _, alarm in aws_cloudwatch_metric_alarm.specials_guard_heartbeat_missing :
      alarm.arn
    ],
    [
      for alarm in aws_cloudwatch_metric_alarm.specials_guard_lambda_errors :
      alarm.arn
    ],
  )
}

resource "aws_cloudwatch_dashboard" "live_feed_ops" {
  dashboard_name = "live-feed-ops-${local.environment_shorthand}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 3
        properties = {
          markdown = <<-EOT
            # EMDS live-feed operations — ${upper(local.environment_shorthand)}

            Green alarm states indicate no active CloudWatch incident. Use the existing [Landing](#dashboards:name=landing-ops-${local.environment_shorthand}), [MDSS](#dashboards:name=mdss-ops-${local.environment_shorthand}) and [FMS](#dashboards:name=fms-ops-${local.environment_shorthand}) dashboards for feed-level detail.
          EOT
        }
      },
      {
        type   = "alarm"
        x      = 0
        y      = 3
        width  = 24
        height = 8
        properties = {
          title   = "Live-feed alarm status"
          alarms  = local.live_feed_operational_alarm_arns
          sortBy  = "stateUpdatedTimestamp"
        }
      },
      {
        type   = "alarm"
        x      = 0
        y      = 11
        width  = 24
        height = 6
        properties = {
          title  = "Alarms needing attention"
          alarms = local.live_feed_operational_alarm_arns
          states = [
            "ALARM",
            "INSUFFICIENT_DATA",
          ]
          sortBy = "stateUpdatedTimestamp"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 17
        width  = 8
        height = 6
        properties = {
          title  = "Transient alarms suppressed"
          region = "eu-west-2"
          view   = "singleValue"
          stat   = "Sum"
          period = 86400
          metrics = [
            [
              "EMDS/CloudWatch",
              "TransientAlarmSuppressedCount",
            ],
          ]
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 17
        width  = 16
        height = 6
        properties = {
          title  = "Transient alarm suppressions"
          region = "eu-west-2"
          view   = "timeSeries"
          stat   = "Sum"
          period = 300
          metrics = [
            [
              "EMDS/CloudWatch",
              "TransientAlarmSuppressedCount",
            ],
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 23
        width  = 24
        height = 7
        properties = {
          title  = "Core queue age"
          region = "eu-west-2"
          stat   = "Maximum"
          period = 60
          metrics = [
            [
              "AWS/SQS",
              "ApproximateAgeOfOldestMessage",
              "QueueName",
              module.load_mdss_event_queue.sqs_queue.name,
              { label = "MDSS load" },
            ],
            [
              "AWS/SQS",
              "ApproximateAgeOfOldestMessage",
              "QueueName",
              module.load_fms_event_queue.sqs_queue.name,
              { label = "FMS load" },
            ],
            [
              "AWS/SQS",
              "ApproximateAgeOfOldestMessage",
              "QueueName",
              aws_sqs_queue.format_fms_json_event_queue.name,
              { label = "FMS format" },
            ],
            [
              "AWS/SQS",
              "ApproximateAgeOfOldestMessage",
              "QueueName",
              aws_sqs_queue.cloudwatch_alarm_debounce.name,
              { label = "Alarm debounce" },
            ],
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 30
        width  = 24
        height = 8
        properties = {
          title  = "Live-feed DLQ age"
          region = "eu-west-2"
          stat   = "Maximum"
          period = 60
          metrics = concat(
            [
              for key, config in local.sqs_dlq_alarm_queues :
              [
                "AWS/SQS",
                "ApproximateAgeOfOldestMessage",
                "QueueName",
                config.queue_name,
                { label = key },
              ]
            ],
            [
              for key, config in local.merge_lambdas :
              [
                "AWS/SQS",
                "ApproximateAgeOfOldestMessage",
                "QueueName",
                "${config.lambda_name}-dlq",
                { label = "merge_${key}" },
              ]
            ],
            [
              [
                "AWS/SQS",
                "ApproximateAgeOfOldestMessage",
                "QueueName",
                aws_sqs_queue.live_feed_incident_events_dlq.name,
                { label = "incident_automation" },
              ],
              [
                "AWS/SQS",
                "ApproximateAgeOfOldestMessage",
                "QueueName",
                aws_sqs_queue.cloudwatch_alarm_debounce_dlq.name,
                { label = "alarm_debounce" },
              ],
            ],
          )
        }
      },
    ]
  })
}
