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
          stat   = "Sum"
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
          title  = "Landing outcomes: OK / retry / final failure"
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
              "LandingUnknownFailCountMdssSpecials"
            ]
          ]
        }
      },

      # --------------------------
      # Final failures log table
      # --------------------------
      {
        type   = "log"
        x      = 0
        y      = 18
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
        y      = 26
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
        y      = 34
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
                  if(message.event = "LANDING_FILE_FAIL",
                  message.source_s3path, null)
                ) as failed_files,
                max(message.attempt) as max_attempt_seen
              by message.feed, message.order_type, message.table
            | sort failed_files desc, retried_files desc, ok_files desc
            | limit 100
          EOT
        }
      }
    ]
  })
}