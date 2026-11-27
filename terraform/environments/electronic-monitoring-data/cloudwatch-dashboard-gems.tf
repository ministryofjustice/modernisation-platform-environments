resource "aws_cloudwatch_dashboard" "gems_ops" {
  dashboard_name = "gems-ops-${local.environment_shorthand}"

  dashboard_body = jsonencode({
    widgets = [
      # --------------------------
      # SQS backlog widgets
      # --------------------------
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "SQS: GEMS events waiting for load_gems"
          region = "eu-west-2"
          stat   = "Maximum"
          period = 60
          metrics = [
            [
              "AWS/SQS",
              "ApproximateNumberOfMessagesVisible",
              "QueueName",
              module.load_gems_event_queue.sqs_queue.name
            ],
            [
              ".",
              "ApproximateNumberOfMessagesNotVisible",
              ".",
              module.load_gems_event_queue.sqs_queue.name
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "SQS DLQ: GEMS events that failed load_gems"
          region = "eu-west-2"
          stat   = "Maximum"
          period = 60
          metrics = [
            [
              "AWS/SQS",
              "ApproximateNumberOfMessagesVisible",
              "QueueName",
              module.load_gems_event_queue.sqs_dlq.name
            ]
          ]
        }
      },

      # --------------------------
      # load_gems lambda health
      # --------------------------
      {
        type   = "metric"
        x      = 0
        y      = 24
        width  = 12
        height = 6
        properties = {
          title  = "Lambda: load_gems Errors / Throttles"
          region = "eu-west-2"
          stat   = "Sum"
          period = 60
          metrics = [
            [
              "AWS/Lambda",
              "Errors",
              "FunctionName",
              module.load_gems_lambda.lambda_function_name
            ],
            [
              ".",
              "Throttles",
              ".",
              module.load_gems_lambda.lambda_function_name
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 24
        width  = 12
        height = 6
        properties = {
          title  = "Lambda: load_gems Duration (p95) + Invocations"
          region = "eu-west-2"
          period = 60
          metrics = [
            [
              "AWS/Lambda",
              "Duration",
              "FunctionName",
              module.load_gems_lambda.lambda_function_name,
              { stat = "p95" }
            ],
            [
              ".",
              "Invocations",
              ".",
              module.load_gems_lambda.lambda_function_name,
              { stat = "Sum" }
            ]
          ]
        }
      },

      # --------------------------
      # GEMS landing bucket processor DLQs
      # --------------------------
      {
        type   = "metric"
        x      = 0
        y      = 30
        width  = 24
        height = 6
        properties = {
          title  = "SQS DLQs: GEMS landing bucket processing"
          region = "eu-west-2"
          stat   = "Maximum"
          period = 60
          metrics = [
            [
              "AWS/SQS",
              "ApproximateNumberOfMessagesVisible",
              "QueueName",
              "process_landing_bucket_files_gems_general-dlq"
            ],
            [
              ".",
              "ApproximateNumberOfMessagesVisible",
              ".",
              "process_landing_bucket_files_gems_ho-dlq"
            ],
            [
              ".",
              "ApproximateNumberOfMessagesVisible",
              ".",
              "process_landing_bucket_files_gems_specials-dlq"
            ]
          ]
        }
      },

      # --------------------------
      # GEMS support-path DLQs
      # --------------------------
      {
        type   = "metric"
        x      = 0
        y      = 36
        width  = 24
        height = 6
        properties = {
          title  = "SQS DLQs: GEMS support path"
          region = "eu-west-2"
          stat   = "Maximum"
          period = 60
          metrics = [
            [
              "AWS/SQS",
              "ApproximateNumberOfMessagesVisible",
              "QueueName",
              "process_gems_metadata-dlq"
            ],
            [
              ".",
              "ApproximateNumberOfMessagesVisible",
              ".",
              "format-gems-json-dlq"
            ],
            [
              ".",
              "ApproximateNumberOfMessagesVisible",
              ".",
              "load_gems-dlq"
            ]
          ]
        }
      },

      # --------------------------
      # load_gems file-level diagnostics
      # --------------------------
      {
        type   = "log"
        x      = 0
        y      = 42
        width  = 24
        height = 8
        properties = {
          title  = "Validation schema failures: load_gems"
          region = "eu-west-2"
          view   = "table"
          query  = <<-EOT
            SOURCE '${module.load_gems_lambda.cloudwatch_log_group.name}'
            | filter ispresent(message.event)
            | filter message.event = "GEMS_FILE_REJECTED_VALIDATION"
            | fields
                @timestamp,
                message.table,
                message.delivery_date,
                message.file_name,
                message.bucket,
                message.s3path,
                message.dataset,
                message.load_status,
                message.reason
            | sort @timestamp desc
            | limit 200
          EOT
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 50
        width  = 24
        height = 8
        properties = {
          title  = "Validation rejections recovery status"
          region = "eu-west-2"
          view   = "table"
          query  = <<-EOT
            SOURCE '${module.load_gems_lambda.cloudwatch_log_group.name}'
            | filter ispresent(message.event)
            | filter message.event in [
                "GEMS_FILE_REJECTED_VALIDATION",
                "GEMS_FILE_OK"
              ]
            | stats
                max(
                  if(
                    message.event = "GEMS_FILE_REJECTED_VALIDATION",
                    @timestamp,
                    0
                  )
                ) as latest_rejection_at,
                max(
                  if(message.event = "GEMS_FILE_OK", @timestamp, 0)
                ) as latest_loaded_at,
                latest(message.bucket) as bucket,
                latest(message.s3path) as s3path,
                latest(message.load_status) as latest_load_status,
                latest(message.reason) as latest_reason
              by message.table, message.delivery_date, message.file_name
            | filter latest_rejection_at > 0
            | sort latest_rejection_at desc
            | limit 200
          EOT
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 58
        width  = 12
        height = 6
        properties = {
          title  = "Validation failures by table"
          region = "eu-west-2"
          view   = "table"
          query  = <<-EOT
            SOURCE '${module.load_gems_lambda.cloudwatch_log_group.name}'
            | filter ispresent(message.event)
            | filter message.event = "GEMS_FILE_REJECTED_VALIDATION"
            | stats
                count_distinct(message.s3path) as rejected_files,
                latest(@timestamp) as latest_rejection,
                latest(message.reason) as latest_reason
              by message.table
            | sort rejected_files desc, latest_rejection desc
            | limit 100
          EOT
        }
      },
      {
        type   = "log"
        x      = 12
        y      = 58
        width  = 12
        height = 6
        properties = {
          title  = "Failure reasons: load_gems"
          region = "eu-west-2"
          view   = "table"
          query  = <<-EOT
            SOURCE '${module.load_gems_lambda.cloudwatch_log_group.name}'
            | filter ispresent(message.event)
            | filter message.event in [
                "GEMS_FILE_FAIL",
                "GEMS_FILE_REJECTED_VALIDATION"
              ]
            | stats
                count_distinct(message.s3path) as affected_files,
                latest(@timestamp) as latest_seen,
                latest(message.table) as latest_table,
                latest(message.file_name) as latest_file
              by message.reason
            | sort affected_files desc, latest_seen desc
            | limit 100
          EOT
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 64
        width  = 24
        height = 8
        properties = {
          title  = "Final failures: load_gems"
          region = "eu-west-2"
          view   = "table"
          query  = <<-EOT
            SOURCE '${module.load_gems_lambda.cloudwatch_log_group.name}'
            | filter ispresent(message.event)
            | filter message.event = "GEMS_FILE_FAIL"
            | stats
                latest(@timestamp) as latest_failure,
                latest(message.bucket) as bucket,
                latest(message.s3path) as s3path,
                latest(message.dataset) as dataset,
                latest(message.load_status) as load_status,
                latest(message.reason) as reason
              by message.table, message.delivery_date, message.file_name
            | sort latest_failure desc
            | limit 200
          EOT
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 72
        width  = 24
        height = 8
        properties = {
          title  = "GEMS outcome summary by table"
          region = "eu-west-2"
          view   = "table"
          query  = <<-EOT
            SOURCE '${module.load_gems_lambda.cloudwatch_log_group.name}'
            | filter ispresent(message.event)
            | filter message.event in [
                "GEMS_FILE_OK",
                "GEMS_FILE_FAIL",
                "GEMS_FILE_REJECTED_VALIDATION"
              ]
            | stats
                count_distinct(
                  if(message.event = "GEMS_FILE_OK", message.s3path, null)
                ) as ok_files,
                count_distinct(
                  if(message.event = "GEMS_FILE_FAIL", message.s3path, null)
                ) as failed_files,
                count_distinct(
                  if(
                    message.event = "GEMS_FILE_REJECTED_VALIDATION",
                    message.s3path,
                    null
                  )
                ) as validation_rejected_files,
                latest(@timestamp) as latest_event
              by message.table
            | sort
                validation_rejected_files desc,
                failed_files desc,
                ok_files desc
            | limit 100
          EOT
        }
      }
    ]
  })
}