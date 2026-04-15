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
      {
        type   = "metric",
        x      = 0,
        y      = 12,
        width  = 12,
        height = 6,
        properties = {
          title  = "Lambda: mdss_reconciler Errors / Throttles"
          region = "eu-west-2"
          stat   = "Sum"
          period = 60
          metrics = [
            ["AWS/Lambda", "Errors", "FunctionName", try(module.mdss_reconciler[0].lambda_function_name, "mdss_reconciler_not_deployed")],
            [".", "Throttles", ".", try(module.mdss_reconciler[0].lambda_function_name, "mdss_reconciler_not_deployed")]
          ]
        }
      },
      {
        type   = "metric",
        x      = 12,
        y      = 12,
        width  = 12,
        height = 6,
        properties = {
          title  = "Lambda: mdss_reconciler Duration (p95) + Invocations"
          region = "eu-west-2"
          period = 300
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", try(module.mdss_reconciler[0].lambda_function_name, "mdss_reconciler_not_deployed"), { stat = "p95" }],
            [".", "Invocations", ".", try(module.mdss_reconciler[0].lambda_function_name, "mdss_reconciler_not_deployed"), { stat = "Sum" }]
          ]
        }
      },
      {
        type   = "log",
        x      = 0,
        y      = 18,
        width  = 24,
        height = 8,
        properties = {
          title  = "Final failures: load_mdss (deduped by file)"
          region = "eu-west-2"
          view   = "table"
          query  = <<-EOT
            SOURCE '${module.load_mdss_lambda.cloudwatch_log_group.name}'
            | filter ispresent(message.event)
            | filter message.event = "MDSS_FILE_FAIL"
            | stats
                latest(@timestamp) as ts,
                max(message.attempt) as max_attempt,
                latest(message.max_receive_count) as max_receive_count,
                latest(message.error_type) as error_type,
                latest(message.retry_policy) as retry_policy,
                latest(message.exception_class) as exception_class,
                latest(message.reason) as reason
              by message.s3path, message.dataset, message.pipeline, message.table
            | sort ts desc
            | limit 200
          EOT
        }
      },
      {
        type   = "log",
        x      = 0,
        y      = 26,
        width  = 24,
        height = 8,
        properties = {
          title  = "Automatic redrive summary: mdss_reconciler"
          region = "eu-west-2"
          view   = "table"
          query  = <<-EOT
            SOURCE '${try(module.mdss_reconciler[0].cloudwatch_log_group.name, "/aws/lambda/mdss_reconciler_not_deployed")}'
            | filter message.event = "MDSS_RECONCILE_COMPLETE"
            | fields
                @timestamp,
                message.redriven_missing,
                message.redriven_stale_started,
                message.redriven_failed_auto_retry,
                message.redriven_failed_retry_once,
                message.skipped_no_retry,
                message.skipped_cooldown,
                message.skipped_max_redrives
            | sort @timestamp desc
            | limit 100
          EOT
        }
      },
      {
        type   = "log",
        x      = 0,
        y      = 34,
        width  = 12,
        height = 6,
        properties = {
          title  = "Final failures by error type"
          region = "eu-west-2"
          view   = "table"
          query  = <<-EOT
            SOURCE '${module.load_mdss_lambda.cloudwatch_log_group.name}'
            | filter ispresent(message.event)
            | filter message.event = "MDSS_FILE_FAIL"
            | stats count_distinct(message.s3path) as failed_files by message.error_type
            | sort failed_files desc
            | limit 50
          EOT
        }
      },
      {
        type   = "log",
        x      = 12,
        y      = 34,
        width  = 12,
        height = 6,
        properties = {
          title  = "Final failures by retry policy"
          region = "eu-west-2"
          view   = "table"
          query  = <<-EOT
            SOURCE '${module.load_mdss_lambda.cloudwatch_log_group.name}'
            | filter ispresent(message.event)
            | filter message.event = "MDSS_FILE_FAIL"
            | stats count_distinct(message.s3path) as failed_files by message.retry_policy
            | sort failed_files desc
            | limit 50
          EOT
        }
      },
      {
        type   = "log",
        x      = 0,
        y      = 40,
        width  = 24,
        height = 6,
        properties = {
          title  = "Warnings: load_mdss"
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
      {
        type   = "log",
        x      = 0,
        y      = 46,
        width  = 24,
        height = 6,
        properties = {
          title  = "Per-file load duration by table (seconds)"
          region = "eu-west-2"
          view   = "table"
          query  = <<-EOT
            SOURCE '${module.load_mdss_lambda.cloudwatch_log_group.name}'
            | filter ispresent(message.event)
            | filter message.event in ["MDSS_FILE_START","MDSS_FILE_OK","MDSS_FILE_OK_AFTER_RETRY","MDSS_FILE_FAIL"]
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
      {
        type   = "log",
        x      = 0,
        y      = 52,
        width  = 24,
        height = 6,
        properties = {
          title  = "Retries: load_mdss (deduped by file)"
          region = "eu-west-2"
          view   = "table"
          query  = <<-EOT
            SOURCE '${module.load_mdss_lambda.cloudwatch_log_group.name}'
            | filter ispresent(message.event)
            | filter message.event = "MDSS_FILE_RETRY"
            | stats
                latest(@timestamp) as ts,
                max(message.attempt) as attempt,
                latest(message.max_receive_count) as max_receive_count,
                latest(message.error_type) as error_type,
                latest(message.retry_policy) as retry_policy,
                latest(message.exception_class) as exception_class,
                latest(message.reason) as reason
              by message.s3path, message.table
            | sort ts desc
            | limit 200
          EOT
        }
      },
      {
        type   = "log",
        x      = 0,
        y      = 58,
        width  = 24,
        height = 6,
        properties = {
          title  = "Recovered: OK after retry"
          region = "eu-west-2"
          view   = "table"
          query  = <<-EOT
            SOURCE '${module.load_mdss_lambda.cloudwatch_log_group.name}'
            | filter ispresent(message.event)
            | filter message.event = "MDSS_FILE_OK_AFTER_RETRY"
            | fields @timestamp, message.table, message.s3path, message.attempt, message.max_receive_count
            | sort @timestamp desc
            | limit 200
          EOT
        }
      },
      {
        type   = "log",
        x      = 0,
        y      = 64,
        width  = 24,
        height = 6,
        properties = {
          title  = "Outcome summary by table"
          region = "eu-west-2"
          view   = "table"
          query  = <<-EOT
            SOURCE '${module.load_mdss_lambda.cloudwatch_log_group.name}'
            | filter ispresent(message.event)
            | filter message.event in ["MDSS_FILE_OK","MDSS_FILE_OK_AFTER_RETRY","MDSS_FILE_FAIL"]
            | stats
                count_distinct(if(message.event="MDSS_FILE_FAIL", message.s3path, null)) as failed_final,
                count_distinct(if(message.event="MDSS_FILE_OK_AFTER_RETRY", message.s3path, null)) as ok_after_retry,
                count_distinct(if(message.event="MDSS_FILE_OK", message.s3path, null)) as ok_first_try,
                round(avg(if(message.event in ["MDSS_FILE_OK","MDSS_FILE_OK_AFTER_RETRY"], message.attempt, null)), 2) as avg_attempt_success,
                max(message.attempt) as max_attempt_seen
              by message.table
            | sort failed_final desc, ok_after_retry desc, avg_attempt_success desc
            | limit 50
          EOT
        }
      }
    ]
  })
}