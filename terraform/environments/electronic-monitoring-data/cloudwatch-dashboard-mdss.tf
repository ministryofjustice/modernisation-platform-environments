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
          title  = "SQS: S3 events waiting for load_mdss"
          region = "eu-west-2"
          stat   = "Sum"
          period = 60
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", module.load_mdss_event_queue.sqs_queue.name],
            [".", "ApproximateNumberOfMessagesNotVisible", ".", module.load_mdss_event_queue.sqs_queue.name]
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
          title  = "SQS DLQ: S3 events that failed load_mdss"
          region = "eu-west-2"
          stat   = "Sum"
          period = 60
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", module.load_mdss_event_queue.sqs_dlq.name]
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
            ["AWS/Lambda", "Errors", "FunctionName", module.load_mdss_lambda.lambda_function_name],
            [".", "Throttles", ".", module.load_mdss_lambda.lambda_function_name]
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
            ["AWS/Lambda", "Duration", "FunctionName", module.load_mdss_lambda.lambda_function_name, { stat = "p95" }],
            [".", "Invocations", ".", module.load_mdss_lambda.lambda_function_name, { stat = "Sum" }]
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
          title  = "FATAL: load_mdss failures (per-file fatal only)"
          region = "eu-west-2"
          view   = "table"
          query  = <<-EOT
            SOURCE '${module.load_mdss_lambda.cloudwatch_log_group.name}'
            | filter ispresent(message.event)
            | filter message.event = "MDSS_FILE_FAIL"
            | filter message.error_type = "fatal"
            | fields @timestamp, message.dataset, message.pipeline, message.table, message.s3path, message.exception_class, @message
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
            SOURCE '${module.load_mdss_lambda.cloudwatch_log_group.name}'
            | filter level = "WARNING" or @message like /\\[WARNING\\]/
            | fields @timestamp, @message
            | sort @timestamp desc
            | limit 200
          EOT
        }
      },

      #Errors by type (last 6h)
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
            SOURCE '${module.load_mdss_lambda.cloudwatch_log_group.name}'
            | filter ispresent(message.event)
            | filter message.event = "MDSS_FILE_FAIL"
            | stats count() as n by coalesce(message.error_type, "UNKNOWN")
            | sort n desc
          EOT
        }
      },

      #Errors by table
      {
        type   = "log",
        x      = 12,
        y      = 26,
        width  = 12,
        height = 6,
        properties = {
          title  = "Errors by table"
          region = "eu-west-2"
          view   = "table"
          query  = <<-EOT
            SOURCE '${module.load_mdss_lambda.cloudwatch_log_group.name}'
            | filter ispresent(message.event)
            | filter message.event = "MDSS_FILE_FAIL"
            | parse message.key /mdss\/(?<tbl>[^\/]+)\//
            | stats count() as failures by coalesce(tbl, message.table, "UNKNOWN")
            | sort failures desc
          EOT
        }
      },

      # Per-file load duration by table (seconds)
      {
        type   = "log",
        x      = 0,
        y      = 32,
        width  = 24,
        height = 6,
        properties = {
          title  = "Per-file load duration by table (seconds)"
          region = "eu-west-2"
          view   = "table"
          query  = <<-EOT
            SOURCE '${module.load_mdss_lambda.cloudwatch_log_group.name}'
            | filter ispresent(message.event)
            | filter message.event in ["MDSS_FILE_START","MDSS_FILE_OK","MDSS_FILE_FAIL"]
            | fields @timestamp, message.table as table, message.s3path as s3path, message.attempt as attempt
            | stats
                count() as n_events,
                min(@timestamp) as start,
                max(@timestamp) as finish,
                (max(@timestamp) - min(@timestamp)) as duration_ms
              by table, s3path, attempt
            | filter n_events >= 2
            | stats
                count() as files,
                round(avg(duration_ms)/1000, 1) as avg_sec,
                round(pct(duration_ms, 95)/1000, 1) as p95_sec,
                round(max(duration_ms)/1000, 1) as max_sec
              by table
            | sort p95_sec desc
            | limit 50
          EOT
        }
      },

      # Failing files
      {
        type   = "log",
        x      = 0,
        y      = 38,
        width  = 24,
        height = 6,
        properties = {
          title  = "Failing files (per-file failures only)"
          region = "eu-west-2"
          view   = "table"
          query  = <<-EOT
            SOURCE '${module.load_mdss_lambda.cloudwatch_log_group.name}'
            | filter ispresent(message.event)
            | filter message.event = "MDSS_FILE_FAIL"
            | fields @timestamp, message.error_type, message.dataset, message.pipeline, message.table, message.bucket, message.key, message.s3path, message.exception_class
            | sort @timestamp desc
            | limit 200
          EOT
        }
      }
    ]
  })
}
