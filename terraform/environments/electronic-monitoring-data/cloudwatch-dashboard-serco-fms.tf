# ------------------------------------------------------------------------------
# Serco FMS secure key-distribution operations dashboard
#
# The custom widgets invoke the read-only dashboard Lambda introduced in PR 10.
# No recipient details, credentials, passwords, challenge values, access-key
# identifiers or CloudTrail object paths are rendered.
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_dashboard" "serco_fms_key_distribution" {
  dashboard_name = format(
    "serco-fms-key-distribution-%s",
    local.environment_shorthand,
  )

  dashboard_body = jsonencode({
    widgets = [
      # ------------------------------------------------------------------------
      # Current workflow and rotation status
      # ------------------------------------------------------------------------

      {
        type   = "custom"
        x      = 0
        y      = 0
        width  = 12
        height = 7

        properties = {
          endpoint = (
            module
            .serco_fms_key_distribution_dashboard
            .lambda_function_arn
          )

          title = "Next rotation and current handover"

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
          endpoint = (
            module
            .serco_fms_key_distribution_dashboard
            .lambda_function_arn
          )

          title = "Latest key rotation by feed"

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

      # ------------------------------------------------------------------------
      # Delivery, acknowledgement and password release
      # ------------------------------------------------------------------------

      {
        type   = "custom"
        x      = 0
        y      = 7
        width  = 24
        height = 8

        properties = {
          endpoint = (
            module
            .serco_fms_key_distribution_dashboard
            .lambda_function_arn
          )

          title = "Secure delivery and acknowledgement"

          params = {
            view = "delivery"
          }

          updateOn = {
            refresh   = true
            resize    = true
            timeRange = false
          }
        }
      },

      # ------------------------------------------------------------------------
      # Rotated-key adoption
      # ------------------------------------------------------------------------

      {
        type   = "custom"
        x      = 0
        y      = 15
        width  = 24
        height = 8

        properties = {
          endpoint = (
            module
            .serco_fms_key_distribution_dashboard
            .lambda_function_arn
          )

          title = "Rotated-key adoption by feed"

          params = {
            view = "adoption"
          }

          updateOn = {
            refresh   = true
            resize    = true
            timeRange = false
          }
        }
      },

      # ------------------------------------------------------------------------
      # Immutable audit timeline
      # ------------------------------------------------------------------------

      {
        type   = "custom"
        x      = 0
        y      = 23
        width  = 24
        height = 10

        properties = {
          endpoint = (
            module
            .serco_fms_key_distribution_dashboard
            .lambda_function_arn
          )

          title = "End-to-end audit timeline"

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

      # ------------------------------------------------------------------------
      # Lambda health
      # ------------------------------------------------------------------------

      {
        type   = "metric"
        x      = 0
        y      = 33
        width  = 12
        height = 7

        properties = {
          title   = "Distribution and dashboard Lambda health"
          region  = data.aws_region.current.name
          view    = "timeSeries"
          stat    = "Sum"
          period  = 300
          stacked = false

          metrics = [
            [
              "AWS/Lambda",
              "Invocations",
              "FunctionName",
              module.send_serco_fms_keys.lambda_function_name,
              {
                label = "Distribution invocations"
              }
            ],
            [
              "AWS/Lambda",
              "Errors",
              "FunctionName",
              module.send_serco_fms_keys.lambda_function_name,
              {
                label = "Distribution errors"
              }
            ],
            [
              "AWS/Lambda",
              "Throttles",
              "FunctionName",
              module.send_serco_fms_keys.lambda_function_name,
              {
                label = "Distribution throttles"
              }
            ],
            [
              "AWS/Lambda",
              "Invocations",
              "FunctionName",
              module.serco_fms_key_distribution_dashboard.lambda_function_name,
              {
                label = "Dashboard invocations"
              }
            ],
            [
              "AWS/Lambda",
              "Errors",
              "FunctionName",
              module.serco_fms_key_distribution_dashboard.lambda_function_name,
              {
                label = "Dashboard errors"
              }
            ],
            [
              "AWS/Lambda",
              "Throttles",
              "FunctionName",
              module.serco_fms_key_distribution_dashboard.lambda_function_name,
              {
                label = "Dashboard throttles"
              }
            ],
          ]
        }
      },

      # ------------------------------------------------------------------------
      # Current alarm states
      # ------------------------------------------------------------------------

      {
        type   = "alarm"
        x      = 12
        y      = 33
        width  = 12
        height = 7

        properties = {
          title  = "Serco FMS handover alarm states"
          sortBy = "stateUpdatedTimestamp"

          states = [
            "ALARM",
            "INSUFFICIENT_DATA",
            "OK",
          ]

          alarms = [
            for _, alarm in
            aws_cloudwatch_metric_alarm.serco_fms_key_distribution_errors :
            alarm.arn
          ]
        }
      },

      # ------------------------------------------------------------------------
      # Recent runtime errors
      # ------------------------------------------------------------------------

      {
        type   = "log"
        x      = 0
        y      = 40
        width  = 24
        height = 10

        properties = {
          title  = "Recent Serco FMS handover errors"
          region = data.aws_region.current.name
          view   = "table"

          query = <<-EOT
            SOURCE '${module.send_serco_fms_keys.cloudwatch_log_group.name}'
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