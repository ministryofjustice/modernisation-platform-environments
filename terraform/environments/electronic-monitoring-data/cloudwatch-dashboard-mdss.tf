resource "aws_cloudwatch_dashboard" "mdss_ops" {
  dashboard_name = "mdss-ops-${local.environment_shorthand}"

  dashboard_body = jsonencode({
    widgets = [
      # --------------------------
      # SQS backlog widgets
      # --------------------------
      {
        type   = "metric",
        x      = 0,
        y      = 0,
        width  = 12,
        height = 6,
        properties = {
          title  = "SQS: load_mdss queue backlog"
          region = "eu-west-2"
          stat   = "Sum"
          period = 60
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", "load_mdss"],
            [".", "ApproximateNumberOfMessagesNotVisible", ".", "load_mdss"]
          ]
        }
      },
      {
        type   = "metric",
        x      = 12,
        y      = 0,
        width  = 12,
        height = 6,
        properties = {
          title  = "SQS: load_mdss DLQ backlog"
          region = "eu-west-2"
          stat   = "Sum"
          period = 60
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", "load_mdss-dlq"]
          ]
        }
      },

      # --------------------------
      # Lambda health widgets
      # --------------------------
      {
        type   = "metric",
        x      = 0,
        y      = 6,
        width  = 12,
        height = 6,
        properties = {
          title  = "Lambda: load_mdss Errors / Throttles"
          region = "eu-west-2"
          stat   = "Sum"
          period = 60
          metrics = [
            ["AWS/Lambda", "Errors", "FunctionName", "load_mdss"],
            [".", "Throttles", ".", "load_mdss"]
          ]
        }
      },
      {
        type   = "metric",
        x      = 12,
        y      = 6,
        width  = 12,
        height = 6,
        properties = {
          title  = "Lambda: load_mdss Duration (p95) + Invocations"
          region = "eu-west-2"
          period = 60
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", "load_mdss", { stat = "p95" }],
            [".", "Invocations", ".", "load_mdss", { stat = "Sum" }]
          ]
        }
      },

      # --------------------------
      # Logs Insights widgets
      # --------------------------

      # Fatal failures only
      {
        type   = "log",
        x      = 0,
        y      = 12,
        width  = 24,
        height = 8,
        properties = {
          title  = "FATAL: load_mdss failures (pipeline aborts / terminal errors)"
          region = "eu-west-2"
          view   = "table"
          query  = <<-EOT
            SOURCE '/aws/lambda/load_mdss'
            | filter @message like /\\[ERROR\\]|Pipeline execution failed|LoadClientJobFailed|DatabaseTerminalException|Terminal exception|Traceback|Task timed out/
            | filter @message not like /"level":"WARNING"|\\[WARNING\\]/
            | fields @timestamp, @message
            | sort @timestamp desc
            | limit 200
          EOT
        }
      },

      # Warnings only
      {
        type   = "log",
        x      = 0,
        y      = 20,
        width  = 24,
        height = 6,
        properties = {
          title  = "WARNINGS: load_mdss (non-fatal signals)"
          region = "eu-west-2"
          view   = "table"
          query  = <<-EOT
            SOURCE '/aws/lambda/load_mdss'
            | filter @message like /"level":"WARNING"|\\[WARNING\\]|Seen non json serializable/
            | fields @timestamp, @message
            | sort @timestamp desc
            | limit 200
          EOT
        }
      },

      {
        type   = "log",
        x      = 0,
        y      = 26,
        width  = 12,
        height = 6,
        properties = {
          title  = "Errors by type (last 6h)"
          region = "eu-west-2"
          view   = "table"
          query  = <<-EOT
            SOURCE '/aws/lambda/load_mdss'
            | filter @message like /\\[ERROR\\]|Pipeline execution failed|Terminal exception|TYPE_MISMATCH|LoadClientJobFailed|DatabaseTerminalException|Traceback|Task timed out/
            | parse @message /(?<err>TYPE_MISMATCH|AccessDenied|EntityNotFoundException|OperationalError|DatabaseTerminalException|LoadClientJobFailed|ValidationError|TimeoutError|Task timed out)/
            | stats count() as n by err
            | sort n desc
          EOT
        }
      },
      {
        type   = "log",
        x      = 12,
        y      = 26,
        width  = 12,
        height = 6,
        properties = {
          title  = "Errors by table (best-effort extraction)"
          region = "eu-west-2"
          view   = "table"
          query  = <<-EOT
            SOURCE '/aws/lambda/load_mdss'
            | filter @message like /Terminal exception in job|Job for/
            | parse @message /job (?<job>[^\\s]+)/
            | parse job /(?<tbl>[^\\.]+)\\./
            | stats count() as failures by tbl
            | sort failures desc
          EOT
        }
      },

      {
        type   = "log",
        x      = 0,
        y      = 32,
        width  = 24,
        height = 6,
        properties = {
          title  = "Failing files (extract table + s3 path when present)"
          region = "eu-west-2"
          view   = "table"
          query  = <<-EOT
            SOURCE '/aws/lambda/load_mdss'
            | filter @message like /Terminal exception|LoadClientJobFailed|TYPE_MISMATCH|\\[ERROR\\] Exception|Pipeline execution failed/
            | parse @message /job (?<job>[^\\s]+)/
            | parse job /(?<tbl>[^\\.]+)\\./
            | parse @message /s3:\\/\\/(?<s3path>[^\\s'"]+)/
            | fields @timestamp, tbl, job, s3path, @message
            | sort @timestamp desc
            | limit 200
          EOT
        }
      }
    ]
  })
}
