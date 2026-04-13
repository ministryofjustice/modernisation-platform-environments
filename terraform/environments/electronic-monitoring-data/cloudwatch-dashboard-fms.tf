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
          stat   = "Sum"
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
          stat   = "Sum"
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
          stat   = "Sum"
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
          stat   = "Sum"
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
              module.process_fms_metadata.lambda_function_name
            ],
            [
              ".",
              "Throttles",
              ".",
              module.process_fms_metadata.lambda_function_name
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
              module.process_fms_metadata.lambda_function_name,
              { stat = "p95" }
            ],
            [
              ".",
              "Invocations",
              ".",
              module.process_fms_metadata.lambda_function_name,
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
              module.format_json_fms_data.lambda_function_name
            ],
            [
              ".",
              "Throttles",
              ".",
              module.format_json_fms_data.lambda_function_name
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
              module.format_json_fms_data.lambda_function_name,
              { stat = "p95" }
            ],
            [
              ".",
              "Invocations",
              ".",
              module.format_json_fms_data.lambda_function_name,
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
          stat   = "Sum"
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
          stat   = "Sum"
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
      }
    ]
  })
}