# ------------------------------------------------------------------------------
# Landing operations dashboard
#
# This dashboard shows the health of process_landing_bucket_files for both
# FMS and MDSS. It focuses on the shared landing stage before files reach the
# raw-formatted bucket and downstream loaders.
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_dashboard" "landing_ops" {
  dashboard_name = "landing-ops-${local.environment_shorthand}"

  dashboard_body = jsonencode({
    widgets = [
      # --------------------------
      # Landing DLQ backlog
      # --------------------------
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 24
        height = 6

        properties = {
          title  = "SQS DLQs: landing bucket processing"
          region = "eu-west-2"
          stat   = "Maximum"
          period = 60

          metrics = [
            [
              "AWS/SQS",
              "ApproximateNumberOfMessagesVisible",
              "QueueName",
              local.live_feed_dlq_names.process_landing_bucket_files_fms_general
            ],
            [
              ".",
              "ApproximateNumberOfMessagesVisible",
              ".",
              local.live_feed_dlq_names.process_landing_bucket_files_fms_ho
            ],
            [
              ".",
              "ApproximateNumberOfMessagesVisible",
              ".",
              local.live_feed_dlq_names.process_landing_bucket_files_fms_specials
            ],
            [
              ".",
              "ApproximateNumberOfMessagesVisible",
              ".",
              local.live_feed_dlq_names.process_landing_bucket_files_mdss_general
            ],
            [
              ".",
              "ApproximateNumberOfMessagesVisible",
              ".",
              local.live_feed_dlq_names.process_landing_bucket_files_mdss_ho
            ],
            [
              ".",
              "ApproximateNumberOfMessagesVisible",
              ".",
              local.live_feed_dlq_names.process_landing_bucket_files_mdss_specials
            ]
          ]
        }
      },

      # --------------------------
      # Landing outcomes
      # --------------------------
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 24
        height = 6

        properties = {
          title  = "Landing outcomes: OK / retry / manual / final failure"
          region = "eu-west-2"
          stat   = "Sum"
          period = 300

          metrics = [
            [
              "EMDS/Landing",
              "LandingFileOkCountFmsGeneral"
            ],
            [
              ".",
              "LandingFileRetryCountFmsGeneral"
            ],
            [
              ".",
              "LandingFileManualRequiredCountFmsGeneral"
            ],
            [
              ".",
              "LandingFileFailCountFmsGeneral"
            ],
            [
              ".",
              "LandingFileOkCountFmsHo"
            ],
            [
              ".",
              "LandingFileRetryCountFmsHo"
            ],
            [
              ".",
              "LandingFileManualRequiredCountFmsHo"
            ],
            [
              ".",
              "LandingFileFailCountFmsHo"
            ],
            [
              ".",
              "LandingFileOkCountFmsSpecials"
            ],
            [
              ".",
              "LandingFileRetryCountFmsSpecials"
            ],
            [
              ".",
              "LandingFileManualRequiredCountFmsSpecials"
            ],
            [
              ".",
              "LandingFileFailCountFmsSpecials"
            ],
            [
              ".",
              "LandingFileOkCountMdssGeneral"
            ],
            [
              ".",
              "LandingFileRetryCountMdssGeneral"
            ],
            [
              ".",
              "LandingFileManualRequiredCountMdssGeneral"
            ],
            [
              ".",
              "LandingFileFailCountMdssGeneral"
            ],
            [
              ".",
              "LandingFileOkCountMdssHo"
            ],
            [
              ".",
              "LandingFileRetryCountMdssHo"
            ],
            [
              ".",
              "LandingFileManualRequiredCountMdssHo"
            ],
            [
              ".",
              "LandingFileFailCountMdssHo"
            ],
            [
              ".",
              "LandingFileOkCountMdssSpecials"
            ],
            [
              ".",
              "LandingFileRetryCountMdssSpecials"
            ],
            [
              ".",
              "LandingFileManualRequiredCountMdssSpecials"
            ],
            [
              ".",
              "LandingFileFailCountMdssSpecials"
            ]
          ]
        }
      },

      # --------------------------
      # Landing final failure breakdown
      # --------------------------
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 24
        height = 6

        properties = {
          title  = "Landing final failures by error class"
          region = "eu-west-2"
          stat   = "Sum"
          period = 300

          metrics = [
            [
              "EMDS/Landing",
              "LandingRetryableTransientFailCountFmsGeneral"
            ],
            [
              ".",
              "LandingNonRetryableDataFailCountFmsGeneral"
            ],
            [
              ".",
              "LandingNonRetryableConfigFailCountFmsGeneral"
            ],
            [
              ".",
              "LandingMissingSourceFailCountFmsGeneral"
            ],
            [
              ".",
              "LandingUnknownFailCountFmsGeneral"
            ],
            [
              ".",
              "LandingRetryableTransientFailCountFmsHo"
            ],
            [
              ".",
              "LandingNonRetryableDataFailCountFmsHo"
            ],
            [
              ".",
              "LandingNonRetryableConfigFailCountFmsHo"
            ],
            [
              ".",
              "LandingMissingSourceFailCountFmsHo"
            ],
            [
              ".",
              "LandingUnknownFailCountFmsHo"
            ],
            [
              ".",
              "LandingRetryableTransientFailCountFmsSpecials"
            ],
            [
              ".",
              "LandingNonRetryableDataFailCountFmsSpecials"
            ],
            [
              ".",
              "LandingNonRetryableConfigFailCountFmsSpecials"
            ],
            [
              ".",
              "LandingMissingSourceFailCountFmsSpecials"
            ],
            [
              ".",
              "LandingUnknownFailCountFmsSpecials"
            ],
            [
              ".",
              "LandingRetryableTransientFailCountMdssGeneral"
            ],
            [
              ".",
              "LandingNonRetryableDataFailCountMdssGeneral"
            ],
            [
              ".",
              "LandingNonRetryableConfigFailCountMdssGeneral"
            ],
            [
              ".",
              "LandingMissingSourceFailCountMdssGeneral"
            ],
            [
              ".",
              "LandingUnknownFailCountMdssGeneral"
            ],
            [
              ".",
              "LandingRetryableTransientFailCountMdssHo"
            ],
            [
              ".",
              "LandingNonRetryableDataFailCountMdssHo"
            ],
            [
              ".",
              "LandingNonRetryableConfigFailCountMdssHo"
            ],
            [
              ".",
              "LandingMissingSourceFailCountMdssHo"
            ],
            [
              ".",
              "LandingUnknownFailCountMdssHo"
            ],
            [
              ".",
              "LandingRetryableTransientFailCountMdssSpecials"
            ],
            [
              ".",
              "LandingNonRetryableDataFailCountMdssSpecials"
            ],
            [
              ".",
              "LandingNonRetryableConfigFailCountMdssSpecials"
            ],
            [
              ".",
              "LandingMissingSourceFailCountMdssSpecials"
            ],
            [
              ".",
              "LandingUnknownFailCountMdssSpecials"
            ]
          ]
        }
      },

      # --------------------------
      # Manual intervention table
      # --------------------------
      {
        type   = "log"
        x      = 0
        y      = 18
        width  = 24
        height = 8

        properties = {
          title  = "Manual intervention required: landing processing"
          region = "eu-west-2"
          view   = "table"

          query = <<-EOT
            SOURCE '/aws/lambda/process_landing_bucket_files_fms_general'
            | SOURCE '/aws/lambda/process_landing_bucket_files_fms_ho'
            | SOURCE '/aws/lambda/process_landing_bucket_files_fms_specials'
            | SOURCE '/aws/lambda/process_landing_bucket_files_mdss_general'
            | SOURCE '/aws/lambda/process_landing_bucket_files_mdss_ho'
            | SOURCE '/aws/lambda/process_landing_bucket_files_mdss_specials'
            | filter ispresent(message.event)
            | filter message.event = "LANDING_FILE_MANUAL_REQUIRED"
            | fields
                @timestamp,
                message.feed,
                message.order_type,
                message.table,
                message.delivery_date,
                message.source_s3path,
                message.destination_s3path,
                message.error_type,
                message.retry_policy,
                message.will_sqs_retry,
                message.reason
            | sort @timestamp desc
            | limit 200
          EOT
        }
      },

      # --------------------------
      # Final failures log table
      # --------------------------
      {
        type   = "log"
        x      = 0
        y      = 26
        width  = 24
        height = 8

        properties = {
          title  = "Final failures: landing processing"
          region = "eu-west-2"
          view   = "table"

          query = <<-EOT
            SOURCE '/aws/lambda/process_landing_bucket_files_fms_general'
            | SOURCE '/aws/lambda/process_landing_bucket_files_fms_ho'
            | SOURCE '/aws/lambda/process_landing_bucket_files_fms_specials'
            | SOURCE '/aws/lambda/process_landing_bucket_files_mdss_general'
            | SOURCE '/aws/lambda/process_landing_bucket_files_mdss_ho'
            | SOURCE '/aws/lambda/process_landing_bucket_files_mdss_specials'
            | filter ispresent(message.event)
            | filter message.event = "LANDING_FILE_FAIL"
            | fields
                @timestamp,
                message.feed,
                message.order_type,
                message.table,
                message.delivery_date,
                message.source_s3path,
                message.destination_s3path,
                message.error_type,
                message.retry_policy,
                message.manual_intervention_required,
                message.reason
            | sort @timestamp desc
            | limit 200
          EOT
        }
      },

      # --------------------------
      # Retry attempts log table
      # --------------------------
      {
        type   = "log"
        x      = 0
        y      = 34
        width  = 24
        height = 8

        properties = {
          title  = "Retry attempts: landing processing"
          region = "eu-west-2"
          view   = "table"

          query = <<-EOT
            SOURCE '/aws/lambda/process_landing_bucket_files_fms_general'
            | SOURCE '/aws/lambda/process_landing_bucket_files_fms_ho'
            | SOURCE '/aws/lambda/process_landing_bucket_files_fms_specials'
            | SOURCE '/aws/lambda/process_landing_bucket_files_mdss_general'
            | SOURCE '/aws/lambda/process_landing_bucket_files_mdss_ho'
            | SOURCE '/aws/lambda/process_landing_bucket_files_mdss_specials'
            | filter ispresent(message.event)
            | filter message.event = "LANDING_FILE_RETRY"
            | fields
                @timestamp,
                message.feed,
                message.order_type,
                message.table,
                message.delivery_date,
                message.source_s3path,
                message.attempt,
                message.max_receive_count,
                message.error_type,
                message.retry_policy,
                message.reason
            | sort @timestamp desc
            | limit 200
          EOT
        }
      },

      # --------------------------
      # Outcome summary by feed/order/table
      # --------------------------
      {
        type   = "log"
        x      = 0
        y      = 42
        width  = 24
        height = 8

        properties = {
          title  = "Landing outcome summary by feed/order/table"
          region = "eu-west-2"
          view   = "table"

          query = <<-EOT
            SOURCE '/aws/lambda/process_landing_bucket_files_fms_general'
            | SOURCE '/aws/lambda/process_landing_bucket_files_fms_ho'
            | SOURCE '/aws/lambda/process_landing_bucket_files_fms_specials'
            | SOURCE '/aws/lambda/process_landing_bucket_files_mdss_general'
            | SOURCE '/aws/lambda/process_landing_bucket_files_mdss_ho'
            | SOURCE '/aws/lambda/process_landing_bucket_files_mdss_specials'
            | filter ispresent(message.event)
            | filter message.event in [
                "LANDING_FILE_OK",
                "LANDING_FILE_RETRY",
                "LANDING_FILE_MANUAL_REQUIRED",
                "LANDING_FILE_FAIL"
              ]
            | stats
                count_distinct(
                  if(message.event = "LANDING_FILE_OK",
                  message.source_s3path, null)
                ) as ok_files,
                count_distinct(
                  if(message.event = "LANDING_FILE_RETRY",
                  message.source_s3path, null)
                ) as retried_files,
                count_distinct(
                  if(message.event = "LANDING_FILE_MANUAL_REQUIRED",
                  message.source_s3path, null)
                ) as manual_required_files,
                count_distinct(
                  if(message.event = "LANDING_FILE_FAIL",
                  message.source_s3path, null)
                ) as failed_files,
                max(message.attempt) as max_attempt_seen
              by message.feed, message.order_type, message.table
            | sort failed_files desc,
                manual_required_files desc,
                retried_files desc,
                ok_files desc
            | limit 100
          EOT
        }
      },

      # --------------------------
      # Recent successful landings
      # --------------------------
      {
        type   = "log"
        x      = 0
        y      = 50
        width  = 24
        height = 8

        properties = {
          title  = "Recent successful landings"
          region = "eu-west-2"
          view   = "table"

          query = <<-EOT
            SOURCE '/aws/lambda/process_landing_bucket_files_fms_general'
            | SOURCE '/aws/lambda/process_landing_bucket_files_fms_ho'
            | SOURCE '/aws/lambda/process_landing_bucket_files_fms_specials'
            | SOURCE '/aws/lambda/process_landing_bucket_files_mdss_general'
            | SOURCE '/aws/lambda/process_landing_bucket_files_mdss_ho'
            | SOURCE '/aws/lambda/process_landing_bucket_files_mdss_specials'
            | filter ispresent(message.event)
            | filter message.event = "LANDING_FILE_OK"
            | fields
                @timestamp,
                message.feed,
                message.order_type,
                message.table,
                message.delivery_date,
                message.source_s3path,
                message.destination_s3path
            | sort @timestamp desc
            | limit 200
          EOT
        }
      },

      # --------------------------
      # Landing failure summary
      # --------------------------
      {
        type   = "log"
        x      = 0
        y      = 58
        width  = 24
        height = 8

        properties = {
          title  = "Landing failures by feed/order/error type"
          region = "eu-west-2"
          view   = "table"

          query = <<-EOT
            SOURCE '/aws/lambda/process_landing_bucket_files_fms_general'
            | SOURCE '/aws/lambda/process_landing_bucket_files_fms_ho'
            | SOURCE '/aws/lambda/process_landing_bucket_files_fms_specials'
            | SOURCE '/aws/lambda/process_landing_bucket_files_mdss_general'
            | SOURCE '/aws/lambda/process_landing_bucket_files_mdss_ho'
            | SOURCE '/aws/lambda/process_landing_bucket_files_mdss_specials'
            | filter ispresent(message.event)
            | filter message.event in [
                "LANDING_FILE_RETRY",
                "LANDING_FILE_MANUAL_REQUIRED",
                "LANDING_FILE_FAIL"
              ]
            | stats
                count_distinct(message.source_s3path) as affected_files,
                latest(@timestamp) as latest_seen,
                latest(message.reason) as latest_reason
              by
                message.feed,
                message.order_type,
                message.error_type,
                message.retry_policy
            | sort affected_files desc, latest_seen desc
            | limit 100
          EOT
        }
      },

      # --------------------------
      # FMS no-data formatter detail
      # --------------------------
      {
        type   = "log"
        x      = 0
        y      = 66
        width  = 24
        height = 8

        properties = {
          title  = "FMS no-data deliveries"
          region = "eu-west-2"
          view   = "table"

          query = <<-EOT
            SOURCE '${module.fms_raw_file_formatter.cloudwatch_log_group.name}'
            | filter @message like /No-data FMS delivery found at/
            | parse @message "*No-data FMS delivery found at *"
                as log_prefix, no_data_path
            | fields
                @timestamp,
                no_data_path,
                @message
            | sort @timestamp desc
            | limit 200
          EOT
        }
      },

      # --------------------------
      # FMS formatter loadability summary
      # --------------------------
      {
        type   = "log"
        x      = 0
        y      = 74
        width  = 24
        height = 8

        properties = {
          title  = "FMS formatter loadability summary"
          region = "eu-west-2"
          view   = "table"

          query = <<-EOT
            SOURCE '${module.fms_raw_file_formatter.cloudwatch_log_group.name}'
            | filter @message like /No-data FMS delivery found at/
                or @message like /Converted /
            | fields
                bin(1h) as hour,
                if(
                  @message like /No-data FMS delivery found at/,
                  1,
                  0
                ) as no_data_delivery,
                if(@message like /Converted /, 1, 0) as converted_event
            | stats
                sum(no_data_delivery) as no_data_deliveries,
                sum(converted_event) as converted_events
              by hour
            | sort hour desc
            | limit 100
          EOT
        }
      }
    ]
  })
}