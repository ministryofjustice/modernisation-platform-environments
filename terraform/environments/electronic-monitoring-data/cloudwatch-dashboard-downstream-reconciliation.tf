resource "aws_cloudwatch_dashboard" "downstream_reconciliation_ops" {
  dashboard_name = (
    "downstream-reconciliation-ops-${local.environment_shorthand}"
  )

  dashboard_body = jsonencode({
    widgets = [
      # ------------------------------------------------------------------------
      # Downstream reconciliation summary
      # ------------------------------------------------------------------------
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 5

        properties = {
          markdown = <<-EOT
            # Downstream reconciliation
            **🟢 CLEAN / IN SYNC** means the latest completed reconciliation
            found no eligible stale positions and the assurance is still current.
            `IN SYNC` is a reconciliation assurance state. It does **not** mean
            every position created in the last few minutes has already reached
            the destination. Live-feed freshness is monitored separately.
            **🔵 RUNNING** reconciliation is actively checking or recovering data.
            **🟠 GAPS** means eligible missing data is known or requires review.
            **🔴 FAILED / STALE** means clean assurance cannot be claimed.
            **⚪ UNKNOWN** means no current reconciliation assurance is available.
            Rolling reconciliation runs every four hours:
            **STAGED :00** | **AC :10** | **EMDI :20**
          EOT
        }
      },
      # ------------------------------------------------------------------------
      # Reconciliation assurance health
      # ------------------------------------------------------------------------
      {
        type   = "alarm"
        x      = 0
        y      = 5
        width  = 12
        height = 5
        properties = {
          title  = "Reconciliation assurance - green = clean / in sync"
          sortBy = "default"
          alarms = [
            for _, alarm in
            aws_cloudwatch_metric_alarm.downstream_reconciliation_assurance_not_clean :
            alarm.arn
          ]
        }
      },
      # ------------------------------------------------------------------------
      # Current reconciliation status
      # ------------------------------------------------------------------------
      {
        type   = "log"
        x      = 12
        y      = 5
        width  = 12
        height = 5
        properties = {
          title  = "Current reconciliation status"
          region = data.aws_region.current.name
          view   = "table"
          query = <<-EOT
            SOURCE '${module.merge_redrive_planner.cloudwatch_log_group.name}'
            \| filter message.event =
                "DOWNSTREAM_RECONCILIATION_CONSUMER_STATUS"
            \| stats
                latest(message.display_status) as status,
                latest(message.assurance_status) as assurance,
                latest(message.active_modes) as activity,
                latest(message.known_missing_positions) as missing,
                latest(message.rolling_age_minutes) as age_minutes
              by message.consumer
            \| sort message.consumer asc
          EOT
        }
      },
      # ------------------------------------------------------------------------
      # Current reconciliation activity
      # ------------------------------------------------------------------------
      {
        type   = "log"
        x      = 0
        y      = 10
        width  = 24
        height = 6
        properties = {
          title  = "Current reconciliation activity and recovery progress"
          region = data.aws_region.current.name
          view   = "table"
          query = <<-EOT
            SOURCE '${module.merge_redrive_planner.cloudwatch_log_group.name}'
            \| filter message.event =
                "DOWNSTREAM_RECONCILIATION_CONSUMER_STATUS"
            \| stats
                latest(message.active_modes) as mode,
                latest(message.active_status) as status,
                latest(message.missing_positions_discovered) as discovered,
                latest(message.positions_recovered) as recovered,
                latest(message.positions_remaining) as remaining,
                latest(message.progress_percent) as progress_percent,
                latest(message.replay_chunks_completed) as chunks_complete,
                latest(message.replay_chunks_planned) as chunks_planned,
                latest(message.started_at_utc) as started,
                latest(message.execution_id) as execution
              by message.consumer
            \| filter mode != "IDLE"
            \| sort message.consumer asc
          EOT
        }
      },

      # ------------------------------------------------------------------------
      # Next rolling reconciliation
      # ------------------------------------------------------------------------
      {
        type   = "metric"
        x      = 0
        y      = 16
        width  = 8
        height = 5

        properties = {
          title  = "Next rolling reconciliation - minutes"
          region = data.aws_region.current.name
          view   = "singleValue"
          stat   = "Maximum"
          period = 300

          metrics = [
            [
              "EM/DownstreamReconciliation",
              "MinutesUntilNextRolling",
              "Environment",
              local.environment_shorthand,
              "Consumer",
              "STAGED",
              "Mode",
              "status",
              {
                label = "STAGED"
              }
            ],
            [
              "EM/DownstreamReconciliation",
              "MinutesUntilNextRolling",
              "Environment",
              local.environment_shorthand,
              "Consumer",
              "AC",
              "Mode",
              "status",
              {
                label = "AC"
              }
            ],
            [
              "EM/DownstreamReconciliation",
              "MinutesUntilNextRolling",
              "Environment",
              local.environment_shorthand,
              "Consumer",
              "EMDI",
              "Mode",
              "status",
              {
                label = "EMDI"
              }
            ],
          ]
        }
      },

      # ------------------------------------------------------------------------
      # Known rolling gaps
      # ------------------------------------------------------------------------
      {
        type   = "metric"
        x      = 8
        y      = 16
        width  = 8
        height = 5
        properties = {
          title  = "Known rolling gaps"
          region = data.aws_region.current.name
          view   = "singleValue"
          stat   = "Maximum"
          period = 300

          metrics = [
            [
              "EM/DownstreamReconciliation",
              "KnownMissingPositions",
              "Environment",
              local.environment_shorthand,
              "Consumer",
              "STAGED",
              "Mode",
              "status",
              {
                label = "STAGED"
              }
            ],
            [
              "EM/DownstreamReconciliation",
              "KnownMissingPositions",
              "Environment",
              local.environment_shorthand,
              "Consumer",
              "AC",
              "Mode",
              "status",
              {
                label = "AC"
              }
            ],
            [
              "EM/DownstreamReconciliation",
              "KnownMissingPositions",
              "Environment",
              local.environment_shorthand,
              "Consumer",
              "EMDI",
              "Mode",
              "status",
              {
                label = "EMDI"
              }
            ],
          ]
        }
      },

      # ------------------------------------------------------------------------
      # Last rolling assurance age
      # ------------------------------------------------------------------------
      {
        type   = "metric"
        x      = 16
        y      = 16
        width  = 8
        height = 5
        properties = {
          title  = "Rolling assurance age - minutes"
          region = data.aws_region.current.name
          view   = "singleValue"
          stat   = "Maximum"
          period = 300

          metrics = [
            [
              "EM/DownstreamReconciliation",
              "RollingAgeMinutes",
              "Environment",
              local.environment_shorthand,
              "Consumer",
              "STAGED",
              "Mode",
              "status",
              {
                label = "STAGED"
              }
            ],
            [
              "EM/DownstreamReconciliation",
              "RollingAgeMinutes",
              "Environment",
              local.environment_shorthand,
              "Consumer",
              "AC",
              "Mode",
              "status",
              {
                label = "AC"
              }
            ],
            [
              "EM/DownstreamReconciliation",
              "RollingAgeMinutes",
              "Environment",
              local.environment_shorthand,
              "Consumer",
              "EMDI",
              "Mode",
              "status",
              {
                label = "EMDI"
              }
            ],
          ]
        }
      },

      # ------------------------------------------------------------------------
      # Historical assurance
      # ------------------------------------------------------------------------
      {
        type   = "metric"
        x      = 0
        y      = 21
        width  = 12
        height = 5
        properties = {
          title  = "Historical audit - missing positions"
          region = data.aws_region.current.name
          view   = "singleValue"
          stat   = "Maximum"
          period = 300

          metrics = [
            [
              "EM/DownstreamReconciliation",
              "HistoricalAuditMissingPositions",
              "Environment",
              local.environment_shorthand,
              "Consumer",
              "AC",
              "Mode",
              "status",
              {
                label = "AC"
              }
            ],
            [
              "EM/DownstreamReconciliation",
              "HistoricalAuditMissingPositions",
              "Environment",
              local.environment_shorthand,
              "Consumer",
              "EMDI",
              "Mode",
              "status",
              {
                label = "EMDI"
              }
            ],
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 21
        width  = 12
        height = 5

        properties = {
          title  = "Historical audit age - hours"
          region = data.aws_region.current.name
          view   = "singleValue"
          stat   = "Maximum"
          period = 300

          metrics = [
            [
              "EM/DownstreamReconciliation",
              "HistoricalAuditAgeHours",
              "Environment",
              local.environment_shorthand,
              "Consumer",
              "AC",
              "Mode",
              "status",
              {
                label = "AC"
              }
            ],
            [
              "EM/DownstreamReconciliation",
              "HistoricalAuditAgeHours",
              "Environment",
              local.environment_shorthand,
              "Consumer",
              "EMDI",
              "Mode",
              "status",
              {
                label = "EMDI"
              }
            ],
          ]
        }
      },

      # ------------------------------------------------------------------------
      # Live merge activity
      # ------------------------------------------------------------------------
      {
        type   = "metric"
        x      = 0
        y      = 26
        width  = 12
        height = 6

        properties = {
          title  = "Live merge successful queries"
          region = data.aws_region.current.name
          view   = "timeSeries"
          stat   = "Sum"
          period = 300

          metrics = [
            [
              "EM/MergeLambdas",
              "SuccessfulQueries",
              "FunctionName",
              module.merge_mdss_staged_position[0].lambda_function_name,
              {
                label = "STAGED"
              }
            ],
            [
              "EM/MergeLambdas",
              "SuccessfulQueries",
              "FunctionName",
              module.merge_ac_position[0].lambda_function_name,
              {
                label = "AC"
              }
            ],
            [
              "EM/MergeLambdas",
              "SuccessfulQueries",
              "FunctionName",
              module.merge_emdi_position[0].lambda_function_name,
              {
                label = "EMDI"
              }
            ],
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 26
        width  = 12
        height = 6

        properties = {
          title  = "Live merge errors and throttles"
          region = data.aws_region.current.name
          view   = "timeSeries"
          stat   = "Sum"
          period = 300

          metrics = [
            [
              "AWS/Lambda",
              "Errors",
              "FunctionName",
              module.merge_mdss_staged_position[0].lambda_function_name,
              {
                label = "STAGED errors"
              }
            ],
            [
              ".",
              "Throttles",
              ".",
              module.merge_mdss_staged_position[0].lambda_function_name,
              {
                label = "STAGED throttles"
              }
            ],
            [
              "AWS/Lambda",
              "Errors",
              "FunctionName",
              module.merge_ac_position[0].lambda_function_name,
              {
                label = "AC errors"
              }
            ],
            [
              ".",
              "Throttles",
              ".",
              module.merge_ac_position[0].lambda_function_name,
              {
                label = "AC throttles"
              }
            ],
            [
              "AWS/Lambda",
              "Errors",
              "FunctionName",
              module.merge_emdi_position[0].lambda_function_name,
              {
                label = "EMDI errors"
              }
            ],
            [
              ".",
              "Throttles",
              ".",
              module.merge_emdi_position[0].lambda_function_name,
              {
                label = "EMDI throttles"
              }
            ],
          ]
        }
      },

      # ------------------------------------------------------------------------
      # Rolling reconciliation activity
      # ------------------------------------------------------------------------
      {
        type   = "metric"
        x      = 0
        y      = 32
        width  = 24
        height = 7

        properties = {
          title  = "Rolling reconciliation activity"
          region = data.aws_region.current.name
          view   = "timeSeries"
          period = 300

          metrics = [
            [
              "EM/DownstreamReconciliation",
              "MissingPositionsDetected",
              "Environment",
              local.environment_shorthand,
              "Consumer",
              "STAGED",
              "Mode",
              "rolling",
              {
                label = "STAGED detected",
                stat  = "Maximum"
              }
            ],
            [
              "EM/DownstreamReconciliation",
              "MissingPositionsDetected",
              "Environment",
              local.environment_shorthand,
              "Consumer",
              "AC",
              "Mode",
              "rolling",
              {
                label = "AC detected",
                stat  = "Maximum"
              }
            ],
            [
              "EM/DownstreamReconciliation",
              "MissingPositionsDetected",
              "Environment",
              local.environment_shorthand,
              "Consumer",
              "EMDI",
              "Mode",
              "rolling",
              {
                label = "EMDI detected",
                stat  = "Maximum"
              }
            ],
            [
              "EM/DownstreamReconciliation",
              "PositionsRecovered",
              "Environment",
              local.environment_shorthand,
              "Consumer",
              "AC",
              "Mode",
              "rolling",
              {
                label = "AC recovered",
                stat  = "Maximum"
              }
            ],
            [
              "EM/DownstreamReconciliation",
              "PositionsRecovered",
              "Environment",
              local.environment_shorthand,
              "Consumer",
              "EMDI",
              "Mode",
              "rolling",
              {
                label = "EMDI recovered",
                stat  = "Maximum"
              }
            ],
            [
              "EM/DownstreamReconciliation",
              "PositionsRemaining",
              "Environment",
              local.environment_shorthand,
              "Consumer",
              "AC",
              "Mode",
              "rolling",
              {
                label = "AC remaining",
                stat  = "Maximum"
              }
            ],
            [
              "EM/DownstreamReconciliation",
              "PositionsRemaining",
              "Environment",
              local.environment_shorthand,
              "Consumer",
              "EMDI",
              "Mode",
              "rolling",
              {
                label = "EMDI remaining",
                stat  = "Maximum"
              }
            ],
          ]
        }
      },

      # ------------------------------------------------------------------------
      # Workflow failures
      # ------------------------------------------------------------------------
      {
        type   = "metric"
        x      = 0
        y      = 39
        width  = 12
        height = 6
        properties = {
          title  = "Reconciliation workflow failures"
          region = data.aws_region.current.name
          view   = "timeSeries"
          stat   = "Sum"
          period = 300

          metrics = [
            [
              "AWS/States",
              "ExecutionsFailed",
              "StateMachineArn",
              module.merge_into_mdss_staged_position.arn,
              {
                label = "STAGED"
              }
            ],
            [
              "AWS/States",
              "ExecutionsFailed",
              "StateMachineArn",
              module.merge_into_mdss_ac_position.arn,
              {
                label = "AC"
              }
            ],
            [
              "AWS/States",
              "ExecutionsFailed",
              "StateMachineArn",
              module.merge_into_emdi_position.arn,
              {
                label = "EMDI"
              }
            ],
            [
              "AWS/States",
              "ExecutionsFailed",
              "StateMachineArn",
              module.downstream_reconciliation_audit.arn,
              {
                label = "Historical audit"
              }
            ],
          ]
        }
      },

      # ------------------------------------------------------------------------
      # Planner health
      # ------------------------------------------------------------------------
      {
        type   = "metric"
        x      = 12
        y      = 39
        width  = 12
        height = 6

        properties = {
          title  = "Reconciliation planner health"
          region = data.aws_region.current.name
          view   = "timeSeries"
          stat   = "Sum"
          period = 300

          metrics = [
            [
              "AWS/Lambda",
              "Errors",
              "FunctionName",
              module.merge_redrive_planner.lambda_function_name,
              {
                label = "Errors"
              }
            ],
            [
              ".",
              "Throttles",
              ".",
              module.merge_redrive_planner.lambda_function_name,
              {
                label = "Throttles"
              }
            ],
          ]
        }
      },

      # ------------------------------------------------------------------------
      # Latest historical audit status
      # ------------------------------------------------------------------------
      {
        type   = "log"
        x      = 0
        y      = 45
        width  = 24
        height = 7

        properties = {
          title  = "Latest historical assurance status"
          region = data.aws_region.current.name
          view   = "table"

          query = <<-EOT
            SOURCE '${module.merge_redrive_planner.cloudwatch_log_group.name}'
            \| filter message.event =
                "DOWNSTREAM_RECONCILIATION_CONSUMER_STATUS"
            \| filter
                message.consumer = "AC"
                or message.consumer = "EMDI"
            \| stats
                latest(message.historical_audit_status) as status,
                latest(
                  message.historical_audit_missing_positions
                ) as missing,
                latest(
                  message.historical_audit_earliest_missing_date
                ) as earliest_missing,
                latest(
                  message.historical_audit_latest_missing_date
                ) as latest_missing,
                latest(
                  message.historical_audit_recommended_action
                ) as recommendation,
                latest(
                  message.historical_audit_deep_cursor_date
                ) as deep_cursor,
                latest(
                  message.historical_audit_age_hours
                ) as age_hours
              by message.consumer
            \| sort message.consumer asc
          EOT
        }
      },

      # ------------------------------------------------------------------------
      # Audit blocker history
      # ------------------------------------------------------------------------
      {
        type   = "log"
        x      = 0
        y      = 52
        width  = 24
        height = 6

        properties = {
          title  = "Historical audit waits - selected dashboard time range"
          region = data.aws_region.current.name
          view   = "table"
          
          query = <<-EOT
            SOURCE '${module.merge_redrive_planner.cloudwatch_log_group.name}'
            \| filter message.event = "DOWNSTREAM_RECONCILIATION_AUDIT_BLOCKED"
            \| fields
                @timestamp,
                message.consumer,
                message.reason
            \| sort @timestamp desc
            \| limit 50
          EOT
        }
      }
    ]
  })
}
