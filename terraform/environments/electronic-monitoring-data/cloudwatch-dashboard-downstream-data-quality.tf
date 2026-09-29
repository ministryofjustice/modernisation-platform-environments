# ------------------------------------------------------------------------------
# Downstream data-quality dashboard
#
# Shows the four downstream invariants first, followed by reconciliation,
# specials remediation, Athena scan, Lambda runtime and recent workflow activity.
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_dashboard" "downstream_data_quality" {
  dashboard_name = "downstream-data-quality-${local.environment_shorthand}"

  dashboard_body = jsonencode({
    widgets = [
      # ------------------------------------------------------------------------
      # Headline invariants
      # Healthy value for each headline metric is zero.
      # ------------------------------------------------------------------------
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 6
        height = 4
        properties = {
          title  = "AC missing positions"
          region = "eu-west-2"
          view   = "singleValue"
          stat   = "Maximum"
          period = 1800
          metrics = [
            [
              "EM/DownstreamReconciliation",
              "MissingPositionsDetected",
              "Environment",
              local.environment_shorthand,
              "Consumer",
              "AC",
              "Mode",
              "rolling"
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 6
        y      = 0
        width  = 6
        height = 4
        properties = {
          title  = "EMDI missing positions"
          region = "eu-west-2"
          view   = "singleValue"
          stat   = "Maximum"
          period = 1800
          metrics = [
            [
              "EM/DownstreamReconciliation",
              "MissingPositionsDetected",
              "Environment",
              local.environment_shorthand,
              "Consumer",
              "EMDI",
              "Mode",
              "rolling"
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 6
        height = 4
        properties = {
          title  = "AC specials remaining"
          region = "eu-west-2"
          view   = "singleValue"
          stat   = "Maximum"
          period = 1800
          metrics = [
            [
              "EM/SpecialsGuard",
              "SpecialsRemaining",
              "Environment",
              local.environment_shorthand,
              "Consumer",
              "AC"
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 18
        y      = 0
        width  = 6
        height = 4
        properties = {
          title  = "EMDI specials remaining"
          region = "eu-west-2"
          view   = "singleValue"
          stat   = "Maximum"
          period = 1800
          metrics = [
            [
              "EM/SpecialsGuard",
              "SpecialsRemaining",
              "Environment",
              local.environment_shorthand,
              "Consumer",
              "EMDI"
            ]
          ]
        }
      },

      # ------------------------------------------------------------------------
      # Reconciliation alarm state
      # ------------------------------------------------------------------------
      {
        type   = "alarm"
        x      = 0
        y      = 4
        width  = 24
        height = 4
        properties = {
          title = "Downstream reconciliation alarms"
          alarms = concat(
            [
              for _, alarm in aws_cloudwatch_metric_alarm.downstream_reconciliation_lambda_errors :
              alarm.arn
            ],
            [
              for _, alarm in aws_cloudwatch_metric_alarm.downstream_reconciliation_failed :
              alarm.arn
            ],
            [
              for _, alarm in aws_cloudwatch_metric_alarm.downstream_reconciliation_heartbeat :
              alarm.arn
            ],
          )
        }
      },

      # ------------------------------------------------------------------------
      # Rolling reconciliation
      # ------------------------------------------------------------------------
      {
        type   = "metric"
        x      = 0
        y      = 8
        width  = 12
        height = 6
        properties = {
          title  = "Rolling: missing positions detected"
          region = "eu-west-2"
          stat   = "Maximum"
          period = 1800
          metrics = [
            [
              "EM/DownstreamReconciliation",
              "MissingPositionsDetected",
              "Environment",
              local.environment_shorthand,
              "Consumer",
              "AC",
              "Mode",
              "rolling",
              { label = "AC" }
            ],
            [
              ".",
              ".",
              ".",
              ".",
              ".",
              "EMDI",
              ".",
              ".",
              { label = "EMDI" }
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 8
        width  = 12
        height = 6
        properties = {
          title  = "Rolling: positions recovered"
          region = "eu-west-2"
          stat   = "Sum"
          period = 1800
          metrics = [
            [
              "EM/DownstreamReconciliation",
              "PositionsRecovered",
              "Environment",
              local.environment_shorthand,
              "Consumer",
              "AC",
              "Mode",
              "rolling",
              { label = "AC" }
            ],
            [
              ".",
              ".",
              ".",
              ".",
              ".",
              "EMDI",
              ".",
              ".",
              { label = "EMDI" }
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 14
        width  = 12
        height = 6
        properties = {
          title  = "Rolling: success / failure"
          region = "eu-west-2"
          stat   = "Sum"
          period = 1800
          metrics = [
            [
              "EM/DownstreamReconciliation",
              "ReconciliationSucceeded",
              "Environment",
              local.environment_shorthand,
              "Consumer",
              "AC",
              "Mode",
              "rolling",
              { label = "AC succeeded" }
            ],
            [
              ".",
              "ReconciliationFailed",
              ".",
              ".",
              ".",
              ".",
              ".",
              ".",
              { label = "AC failed" }
            ],
            [
              ".",
              "ReconciliationSucceeded",
              ".",
              ".",
              ".",
              "EMDI",
              ".",
              ".",
              { label = "EMDI succeeded" }
            ],
            [
              ".",
              "ReconciliationFailed",
              ".",
              ".",
              ".",
              ".",
              ".",
              ".",
              { label = "EMDI failed" }
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 14
        width  = 12
        height = 6
        properties = {
          title  = "Rolling: guard heartbeat"
          region = "eu-west-2"
          stat   = "Sum"
          period = 1800
          metrics = [
            [
              "EM/DownstreamReconciliation",
              "GuardHeartbeat",
              "Environment",
              local.environment_shorthand,
              "Consumer",
              "AC",
              "Mode",
              "rolling",
              { label = "AC" }
            ],
            [
              ".",
              ".",
              ".",
              ".",
              ".",
              "EMDI",
              ".",
              ".",
              { label = "EMDI" }
            ]
          ]
        }
      },

      # ------------------------------------------------------------------------
      # Historical reconciliation and approvals
      # ------------------------------------------------------------------------
      {
        type   = "metric"
        x      = 0
        y      = 20
        width  = 12
        height = 6
        properties = {
          title  = "Historical: replay chunk progress"
          region = "eu-west-2"
          stat   = "Sum"
          period = 3600
          metrics = [
            [
              "EM/DownstreamReconciliation",
              "ReplayChunksPlanned",
              "Environment",
              local.environment_shorthand,
              "Consumer",
              "AC",
              "Mode",
              "historical",
              { label = "AC planned" }
            ],
            [
              ".",
              "ReplayChunksCompleted",
              ".",
              ".",
              ".",
              ".",
              ".",
              ".",
              { label = "AC completed" }
            ],
            [
              ".",
              "ReplayChunksFailed",
              ".",
              ".",
              ".",
              ".",
              ".",
              ".",
              { label = "AC failed" }
            ],
            [
              ".",
              "ReplayChunksPlanned",
              ".",
              ".",
              ".",
              "EMDI",
              ".",
              ".",
              { label = "EMDI planned" }
            ],
            [
              ".",
              "ReplayChunksCompleted",
              ".",
              ".",
              ".",
              ".",
              ".",
              ".",
              { label = "EMDI completed" }
            ],
            [
              ".",
              "ReplayChunksFailed",
              ".",
              ".",
              ".",
              ".",
              ".",
              ".",
              { label = "EMDI failed" }
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 20
        width  = 12
        height = 6
        properties = {
          title  = "Historical: approval decisions"
          region = "eu-west-2"
          stat   = "Sum"
          period = 3600
          metrics = [
            [
              "EM/DownstreamReconciliation",
              "ApprovalPending",
              "Environment",
              local.environment_shorthand,
              "Consumer",
              "AC",
              "Mode",
              "historical",
              { label = "AC pending" }
            ],
            [
              ".",
              "ApprovalGranted",
              ".",
              ".",
              ".",
              ".",
              ".",
              ".",
              { label = "AC granted" }
            ],
            [
              ".",
              "ApprovalRejected",
              ".",
              ".",
              ".",
              ".",
              ".",
              ".",
              { label = "AC rejected" }
            ],
            [
              ".",
              "ApprovalPending",
              ".",
              ".",
              ".",
              "EMDI",
              ".",
              ".",
              { label = "EMDI pending" }
            ],
            [
              ".",
              "ApprovalGranted",
              ".",
              ".",
              ".",
              ".",
              ".",
              ".",
              { label = "EMDI granted" }
            ],
            [
              ".",
              "ApprovalRejected",
              ".",
              ".",
              ".",
              ".",
              ".",
              ".",
              { label = "EMDI rejected" }
            ]
          ]
        }
      },

      # ------------------------------------------------------------------------
      # Specials remediation
      # ------------------------------------------------------------------------
      {
        type   = "metric"
        x      = 0
        y      = 26
        width  = 12
        height = 6
        properties = {
          title  = "Specials: detected / remaining"
          region = "eu-west-2"
          stat   = "Maximum"
          period = 1800
          metrics = [
            [
              "EM/SpecialsGuard",
              "SpecialsDetected",
              "Environment",
              local.environment_shorthand,
              "Consumer",
              "AC",
              { label = "AC detected" }
            ],
            [
              ".",
              "SpecialsRemaining",
              ".",
              ".",
              ".",
              ".",
              { label = "AC remaining" }
            ],
            [
              ".",
              "SpecialsDetected",
              ".",
              ".",
              ".",
              "EMDI",
              { label = "EMDI detected" }
            ],
            [
              ".",
              "SpecialsRemaining",
              ".",
              ".",
              ".",
              ".",
              { label = "EMDI remaining" }
            ]
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
          title  = "Specials: archived / deleted"
          region = "eu-west-2"
          stat   = "Sum"
          period = 1800
          metrics = [
            [
              "EM/SpecialsGuard",
              "SpecialsArchived",
              "Environment",
              local.environment_shorthand,
              "Consumer",
              "AC",
              { label = "AC archived" }
            ],
            [
              ".",
              "SpecialsDeleted",
              ".",
              ".",
              ".",
              ".",
              { label = "AC deleted" }
            ],
            [
              ".",
              "SpecialsArchived",
              ".",
              ".",
              ".",
              "EMDI",
              { label = "EMDI archived" }
            ],
            [
              ".",
              "SpecialsDeleted",
              ".",
              ".",
              ".",
              ".",
              { label = "EMDI deleted" }
            ]
          ]
        }
      },

      # ------------------------------------------------------------------------
      # Athena scan volume and query count
      # ------------------------------------------------------------------------
      {
        type   = "metric"
        x      = 0
        y      = 32
        width  = 12
        height = 6
        properties = {
          title  = "Reconciliation Athena bytes scanned"
          region = "eu-west-2"
          stat   = "Sum"
          period = 1800
          metrics = [
            [
              "EM/DownstreamReconciliation",
              "AthenaBytesScanned",
              "Environment",
              local.environment_shorthand,
              "Consumer",
              "AC",
              "Mode",
              "rolling",
              { label = "AC rolling" }
            ],
            [
              ".",
              ".",
              ".",
              ".",
              ".",
              "EMDI",
              ".",
              ".",
              { label = "EMDI rolling" }
            ],
            [
              ".",
              ".",
              ".",
              ".",
              ".",
              "AC",
              ".",
              "historical",
              { label = "AC historical" }
            ],
            [
              ".",
              ".",
              ".",
              ".",
              ".",
              "EMDI",
              ".",
              "historical",
              { label = "EMDI historical" }
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 32
        width  = 12
        height = 6
        properties = {
          title  = "Reconciliation Athena query count"
          region = "eu-west-2"
          stat   = "Sum"
          period = 1800
          metrics = [
            [
              "EM/DownstreamReconciliation",
              "AthenaQueryCount",
              "Environment",
              local.environment_shorthand,
              "Consumer",
              "AC",
              "Mode",
              "rolling",
              { label = "AC rolling" }
            ],
            [
              ".",
              ".",
              ".",
              ".",
              ".",
              "EMDI",
              ".",
              ".",
              { label = "EMDI rolling" }
            ],
            [
              ".",
              ".",
              ".",
              ".",
              ".",
              "AC",
              ".",
              "historical",
              { label = "AC historical" }
            ],
            [
              ".",
              ".",
              ".",
              ".",
              ".",
              "EMDI",
              ".",
              "historical",
              { label = "EMDI historical" }
            ]
          ]
        }
      },

      # ------------------------------------------------------------------------
      # Runtime health
      # ------------------------------------------------------------------------
      {
        type   = "metric"
        x      = 0
        y      = 38
        width  = 12
        height = 6
        properties = {
          title  = "Planner Lambda: errors / throttles"
          region = "eu-west-2"
          stat   = "Sum"
          period = 300
          metrics = [
            [
              "AWS/Lambda",
              "Errors",
              "FunctionName",
              module.merge_redrive_planner.lambda_function_name
            ],
            [
              ".",
              "Throttles",
              ".",
              module.merge_redrive_planner.lambda_function_name
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 38
        width  = 12
        height = 6
        properties = {
          title  = "Planner Lambda: duration / invocations"
          region = "eu-west-2"
          period = 300
          metrics = [
            [
              "AWS/Lambda",
              "Duration",
              "FunctionName",
              module.merge_redrive_planner.lambda_function_name,
              { stat = "p95" }
            ],
            [
              ".",
              "Invocations",
              ".",
              module.merge_redrive_planner.lambda_function_name,
              { stat = "Sum" }
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 44
        width  = 12
        height = 6
        properties = {
          title  = "Approval Lambda: errors / throttles"
          region = "eu-west-2"
          stat   = "Sum"
          period = 300
          metrics = [
            [
              "AWS/Lambda",
              "Errors",
              "FunctionName",
              module.merge_redrive_approval.lambda_function_name
            ],
            [
              ".",
              "Throttles",
              ".",
              module.merge_redrive_approval.lambda_function_name
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 44
        width  = 12
        height = 6
        properties = {
          title  = "Approval Lambda: duration / invocations"
          region = "eu-west-2"
          period = 300
          metrics = [
            [
              "AWS/Lambda",
              "Duration",
              "FunctionName",
              module.merge_redrive_approval.lambda_function_name,
              { stat = "p95" }
            ],
            [
              ".",
              "Invocations",
              ".",
              module.merge_redrive_approval.lambda_function_name,
              { stat = "Sum" }
            ]
          ]
        }
      },

      # ------------------------------------------------------------------------
      # Recent reconciliation activity
      # ------------------------------------------------------------------------
      {
        type   = "log"
        x      = 0
        y      = 50
        width  = 24
        height = 8
        properties = {
          title  = "Recent downstream reconciliation actions"
          region = "eu-west-2"
          view   = "table"
          query  = <<-EOT
            SOURCE '${module.merge_redrive_planner.cloudwatch_log_group.name}'
            | filter message.event = "DOWNSTREAM_RECONCILIATION_ACTION_COMPLETE"
            | fields
                @timestamp,
                message.consumer,
                message.mode,
                message.action,
                message.status
            | sort @timestamp desc
            | limit 200
          EOT
        }
      }
    ]
  })
}