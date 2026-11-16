resource "aws_cloudwatch_dashboard" "fms_ops" {
  dashboard_name = "fms-ops-${local.environment_shorthand}"

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
          title  = "SQS: FMS events waiting for load_fms"
          region = "eu-west-2"
          stat   = "Maximum"
          period = 60
          metrics = [
            [
              "AWS/SQS",
              "ApproximateNumberOfMessagesVisible",
              "QueueName",
              module.load_fms_event_queue.sqs_queue.name
            ],
            [
              ".",
              "ApproximateNumberOfMessagesNotVisible",
              ".",
              module.load_fms_event_queue.sqs_queue.name
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
          title  = "SQS DLQ: FMS events that failed load_fms"
          region = "eu-west-2"
          stat   = "Maximum"
          period = 60
          metrics = [
            [
              "AWS/SQS",
              "ApproximateNumberOfMessagesVisible",
              "QueueName",
              module.load_fms_event_queue.sqs_dlq.name
            ]
          ]
        }
      },

      # --------------------------
      # format_fms_json queue health
      # --------------------------
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "SQS: format_fms_json queue backlog"
          region = "eu-west-2"
          stat   = "Maximum"
          period = 60
          metrics = [
            [
              "AWS/SQS",
              "ApproximateNumberOfMessagesVisible",
              "QueueName",
              aws_sqs_queue.format_fms_json_event_queue.name
            ],
            [
              ".",
              "ApproximateNumberOfMessagesNotVisible",
              ".",
              aws_sqs_queue.format_fms_json_event_queue.name
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "SQS DLQ: format_fms_json failures"
          region = "eu-west-2"
          stat   = "Maximum"
          period = 60
          metrics = [
            [
              "AWS/SQS",
              "ApproximateNumberOfMessagesVisible",
              "QueueName",
              aws_sqs_queue.format_fms_json_event_dlq.name
            ]
          ]
        }
      },

      # --------------------------
      # process_fms_metadata lambda health
      # --------------------------
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "Lambda: process_fms_metadata Errors / Throttles"
          region = "eu-west-2"
          stat   = "Sum"
          period = 60
          metrics = [
            [
              "AWS/Lambda",
              "Errors",
              "FunctionName",
              module.fms_expected_file_processor.lambda_function_name
            ],
            [
              ".",
              "Throttles",
              ".",
              module.fms_expected_file_processor.lambda_function_name
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "Lambda: process_fms_metadata Duration (p95) + Invocations"
          region = "eu-west-2"
          period = 60
          metrics = [
            [
              "AWS/Lambda",
              "Duration",
              "FunctionName",
              module.fms_expected_file_processor.lambda_function_name,
              { stat = "p95" }
            ],
            [
              ".",
              "Invocations",
              ".",
              module.fms_expected_file_processor.lambda_function_name,
              { stat = "Sum" }
            ]
          ]
        }
      },

      # --------------------------
      # format_json_fms_data lambda health
      # --------------------------
      {
        type   = "metric"
        x      = 0
        y      = 18
        width  = 12
        height = 6
        properties = {
          title  = "Lambda: format_json_fms_data Errors / Throttles"
          region = "eu-west-2"
          stat   = "Sum"
          period = 60
          metrics = [
            [
              "AWS/Lambda",
              "Errors",
              "FunctionName",
              module.fms_raw_file_formatter.lambda_function_name
            ],
            [
              ".",
              "Throttles",
              ".",
              module.fms_raw_file_formatter.lambda_function_name
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 18
        width  = 12
        height = 6
        properties = {
          title  = "Lambda: format_json_fms_data Duration (p95) + Invocations"
          region = "eu-west-2"
          period = 60
          metrics = [
            [
              "AWS/Lambda",
              "Duration",
              "FunctionName",
              module.fms_raw_file_formatter.lambda_function_name,
              { stat = "p95" }
            ],
            [
              ".",
              "Invocations",
              ".",
              module.fms_raw_file_formatter.lambda_function_name,
              { stat = "Sum" }
            ]
          ]
        }
      },

      # --------------------------
      # load_fms lambda health
      # --------------------------
      {
        type   = "metric"
        x      = 0
        y      = 24
        width  = 12
        height = 6
        properties = {
          title  = "Lambda: load_fms Errors / Throttles"
          region = "eu-west-2"
          stat   = "Sum"
          period = 60
          metrics = [
            [
              "AWS/Lambda",
              "Errors",
              "FunctionName",
              module.load_fms_lambda.lambda_function_name
            ],
            [
              ".",
              "Throttles",
              ".",
              module.load_fms_lambda.lambda_function_name
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
          title  = "Lambda: load_fms Duration (p95) + Invocations"
          region = "eu-west-2"
          period = 60
          metrics = [
            [
              "AWS/Lambda",
              "Duration",
              "FunctionName",
              module.load_fms_lambda.lambda_function_name,
              { stat = "p95" }
            ],
            [
              ".",
              "Invocations",
              ".",
              module.load_fms_lambda.lambda_function_name,
              { stat = "Sum" }
            ]
          ]
        }
      },

      # --------------------------
      # FMS landing bucket processor DLQs
      # --------------------------
      {
        type   = "metric"
        x      = 0
        y      = 30
        width  = 24
        height = 6
        properties = {
          title  = "SQS DLQs: FMS landing bucket processing"
          region = "eu-west-2"
          stat   = "Maximum"
          period = 60
          metrics = [
            [
              "AWS/SQS",
              "ApproximateNumberOfMessagesVisible",
              "QueueName",
              "process_landing_bucket_files_fms_general-dlq"
            ],
            [
              ".",
              "ApproximateNumberOfMessagesVisible",
              ".",
              "process_landing_bucket_files_fms_ho-dlq"
            ],
            [
              ".",
              "ApproximateNumberOfMessagesVisible",
              ".",
              "process_landing_bucket_files_fms_specials-dlq"
            ]
          ]
        }
      },

      # --------------------------
      # FMS support-path DLQs
      # --------------------------
      {
        type   = "metric"
        x      = 0
        y      = 36
        width  = 24
        height = 6
        properties = {
          title  = "SQS DLQs: FMS support path"
          region = "eu-west-2"
          stat   = "Maximum"
          period = 60
          metrics = [
            [
              "AWS/SQS",
              "ApproximateNumberOfMessagesVisible",
              "QueueName",
              "process_fms_metadata-dlq"
            ],
            [
              ".",
              "ApproximateNumberOfMessagesVisible",
              ".",
              "format-fms-json-dlq"
            ],
            [
              ".",
              "ApproximateNumberOfMessagesVisible",
              ".",
              "load_fms-dlq"
            ]
          ]
        }
      },

      # --------------------------
      # load_fms file-level diagnostics
      # --------------------------
      {
        type   = "log"
        x      = 0
        y      = 42
        width  = 24
        height = 8
        properties = {
          title  = "Validation schema failures: load_fms"
          region = "eu-west-2"
          view   = "table"
          query  = <<-EOT
            SOURCE '${module.load_fms_lambda.cloudwatch_log_group.name}'
            | filter ispresent(message.event)
            | filter message.event = "FMS_FILE_REJECTED_VALIDATION"
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
            SOURCE '${module.load_fms_lambda.cloudwatch_log_group.name}'
            | filter ispresent(message.event)
            | filter message.event in [
                "FMS_FILE_REJECTED_VALIDATION",
                "FMS_FILE_OK"
              ]
            | stats
                max(
                  if(
                    message.event = "FMS_FILE_REJECTED_VALIDATION",
                    @timestamp,
                    0
                  )
                ) as latest_rejection_at,
                max(
                  if(message.event = "FMS_FILE_OK", @timestamp, 0)
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
            SOURCE '${module.load_fms_lambda.cloudwatch_log_group.name}'
            | filter ispresent(message.event)
            | filter message.event = "FMS_FILE_REJECTED_VALIDATION"
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
          title  = "Failure reasons: load_fms"
          region = "eu-west-2"
          view   = "table"
          query  = <<-EOT
            SOURCE '${module.load_fms_lambda.cloudwatch_log_group.name}'
            | filter ispresent(message.event)
            | filter message.event in [
                "FMS_FILE_FAIL",
                "FMS_FILE_REJECTED_VALIDATION"
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
          title  = "Final failures: load_fms"
          region = "eu-west-2"
          view   = "table"
          query  = <<-EOT
            SOURCE '${module.load_fms_lambda.cloudwatch_log_group.name}'
            | filter ispresent(message.event)
            | filter message.event = "FMS_FILE_FAIL"
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
          title  = "FMS outcome summary by table"
          region = "eu-west-2"
          view   = "table"
          query  = <<-EOT
            SOURCE '${module.load_fms_lambda.cloudwatch_log_group.name}'
            | filter ispresent(message.event)
            | filter message.event in [
                "FMS_FILE_OK",
                "FMS_FILE_FAIL",
                "FMS_FILE_REJECTED_VALIDATION"
              ]
            | stats
                count_distinct(
                  if(message.event = "FMS_FILE_OK", message.s3path, null)
                ) as ok_files,
                count_distinct(
                  if(message.event = "FMS_FILE_FAIL", message.s3path, null)
                ) as failed_files,
                count_distinct(
                  if(
                    message.event = "FMS_FILE_REJECTED_VALIDATION",
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