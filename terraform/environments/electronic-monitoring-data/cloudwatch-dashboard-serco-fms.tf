# ------------------------------------------------------------------------------
# Serco FMS secure key-distribution operations dashboard
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_dashboard" "serco_fms_key_distribution" {
  dashboard_name = "serco-fms-key-distribution-${local.environment_shorthand}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "custom"
        x      = 0
        y      = 0
        width  = 12
        height = 7

        properties = {
          endpoint = module.serco_fms_key_distribution_dashboard.lambda_function_arn
          title    = "Next rotation and current handover"

          params = {
            view = "summary"
          }

          updateOn = {
            refresh   = true
            resize    = true
            timeRange = false
          }
        }
      },
      {
        type   = "custom"
        x      = 12
        y      = 0
        width  = 12
        height = 7

        properties = {
          endpoint = module.serco_fms_key_distribution_dashboard.lambda_function_arn
          title    = "Latest key rotation by feed"

          params = {
            view = "feed_rotations"
          }

          updateOn = {
            refresh   = true
            resize    = true
            timeRange = false
          }
        }
      },
      {
        type   = "custom"
        x      = 0
        y      = 7
        width  = 12
        height = 8

        properties = {
          endpoint = module.serco_fms_key_distribution_dashboard.lambda_function_arn
          title    = "Restricted: approved recipients"

          params = {
            view           = "allowlist"
            show_sensitive = true
          }

          updateOn = {
            refresh   = true
            resize    = true
            timeRange = false
          }
        }
      },
      {
        type   = "custom"
        x      = 12
        y      = 7
        width  = 12
        height = 8

        properties = {
          endpoint = module.serco_fms_key_distribution_dashboard.lambda_function_arn
          title    = "Restricted: file claim activity"

          params = {
            view           = "claim_activity"
            show_sensitive = true
          }

          updateOn = {
            refresh   = true
            resize    = true
            timeRange = false
          }
        }
      },
      {
        type   = "custom"
        x      = 0
        y      = 15
        width  = 24
        height = 8

        properties = {
          endpoint = module.serco_fms_key_distribution_dashboard.lambda_function_arn
          title    = "Restricted: GOV.UK Notify recipient status"

          params = {
            view           = "notification_status"
            show_sensitive = true
          }

          updateOn = {
            refresh   = true
            resize    = true
            timeRange = false
          }
        }
      },
      {
        type   = "custom"
        x      = 0
        y      = 23
        width  = 24
        height = 8

        properties = {
          endpoint = module.serco_fms_key_distribution_dashboard.lambda_function_arn
          title    = "Rotated-key adoption by feed"

          params = {
            view = "key_access"
          }

          updateOn = {
            refresh   = true
            resize    = true
            timeRange = false
          }
        }
      },
      {
        type   = "custom"
        x      = 0
        y      = 31
        width  = 24
        height = 10

        properties = {
          endpoint = module.serco_fms_key_distribution_dashboard.lambda_function_arn
          title    = "End-to-end immutable event timeline"

          params = {
            view = "event_timeline"
          }

          updateOn = {
            refresh   = true
            resize    = true
            timeRange = false
          }
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 41
        width  = 12
        height = 7

        properties = {
          title   = "Lambda invocations and errors"
          region  = "eu-west-2"
          view    = "timeSeries"
          stat    = "Sum"
          period  = 300
          stacked = false

          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", module.send_serco_fms_keys.lambda_function_name, { label = "Distribution invocations" }],
            ["AWS/Lambda", "Errors", "FunctionName", module.send_serco_fms_keys.lambda_function_name, { label = "Distribution errors" }],
            ["AWS/Lambda", "Invocations", "FunctionName", module.serco_fms_claim_page.lambda_function_name, { label = "Claim invocations" }],
            ["AWS/Lambda", "Errors", "FunctionName", module.serco_fms_claim_page.lambda_function_name, { label = "Claim errors" }],
            ["AWS/Lambda", "Invocations", "FunctionName", module.serco_fms_key_access_observer.lambda_function_name, { label = "Observer invocations" }],
            ["AWS/Lambda", "Errors", "FunctionName", module.serco_fms_key_access_observer.lambda_function_name, { label = "Observer errors" }],
            ["AWS/Lambda", "Invocations", "FunctionName", module.serco_fms_key_distribution_dashboard.lambda_function_name, { label = "Dashboard invocations" }],
            ["AWS/Lambda", "Errors", "FunctionName", module.serco_fms_key_distribution_dashboard.lambda_function_name, { label = "Dashboard errors" }],
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 41
        width  = 12
        height = 7

        properties = {
          title  = "Serco FMS Lambda alarm states"
          region = "eu-west-2"
          view   = "timeSeries"

          annotations = {
            alarms = [
              for _, alarm in aws_cloudwatch_metric_alarm.serco_fms_key_distribution_errors : alarm.arn
            ]
          }
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 48
        width  = 24
        height = 10

        properties = {
          title  = "Recent errors, failures and notification problems"
          region = "eu-west-2"
          view   = "table"

          query = <<-EOT
            SOURCE '${module.send_serco_fms_keys.cloudwatch_log_group.name}'
            | SOURCE '${module.serco_fms_claim_page.cloudwatch_log_group.name}'
            | SOURCE '${module.serco_fms_key_access_observer.cloudwatch_log_group.name}'
            | SOURCE '${module.serco_fms_key_distribution_dashboard.cloudwatch_log_group.name}'
            | fields @timestamp, @log, @logStream, level, service, @message
            | filter level = "ERROR"
                or @message like /Traceback|Exception|failed|Failure/
            | sort @timestamp desc
            | limit 100
          EOT
        }
      },
    ]
  })
}
