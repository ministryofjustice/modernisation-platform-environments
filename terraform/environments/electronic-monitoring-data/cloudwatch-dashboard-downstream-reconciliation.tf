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
        height = 3

        properties = {
          markdown = <<-EOT
            # Downstream reconciliation

            Rolling reconciliation runs every four hours:
            **STAGED :00** | **AC :10** | **EMDI :20**

            `Known rolling gaps` shows the latest reconciliation assurance.
            It is not a latest-position freshness measurement.
          EOT
        }
      },

      # ------------------------------------------------------------------------
      # Next rolling reconciliation
      # ------------------------------------------------------------------------
      {
        type   = "metric"
        x      = 0
        y      = 3
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
        y      = 3
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
        y      = 3
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
        y      = 8
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
        y      = 8
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
        y      = 13
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
        y      = 13
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
        y      = 19
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
        y      = 26
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
        y      = 26
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
        y      = 32
        width  = 24
        height = 7

        properties = {
          title  = "Latest historical assurance status"
          region = data.aws_region.current.name
          view   = "table"

          query = <<-EOT
            SOURCE '${module.merge_redrive_planner.cloudwatch_log_group.name}'
            | filter message.event = "DOWNSTREAM_RECONCILIATION_AUDIT_STATUS"
            | fields
                @timestamp,
                message.consumer,
                message.status,
                message.missing_positions,
                message.earliest_missing_date,
                message.latest_missing_date,
                message.recommended_action,
                message.deep_cursor_date
            | sort @timestamp desc
            | limit 20
          EOT
        }
      },

      # ------------------------------------------------------------------------
      # Audit blocker history
      # ------------------------------------------------------------------------
      {
        type   = "log"
        x      = 0
        y      = 39
        width  = 24
        height = 6

        properties = {
          title  = "Historical audit waits"
          region = data.aws_region.current.name
          view   = "table"

          query = <<-EOT
            SOURCE '${module.merge_redrive_planner.cloudwatch_log_group.name}'
            | filter message.event = "DOWNSTREAM_RECONCILIATION_AUDIT_BLOCKED"
            | fields
                @timestamp,
                message.consumer,
                message.reason
            | sort @timestamp desc
            | limit 50
          EOT
        }
      }
    ]
  })
}
