locals {
  live_feed_dlq_names = {
    process_landing_bucket_files_fms_general  = "-process_landing_bucket_files_fms_general-dlq"
    process_landing_bucket_files_fms_ho       = "-process_landing_bucket_files_fms_ho-dlq"
    process_landing_bucket_files_fms_specials = "-process_landing_bucket_files_fms_specials-dlq"

    process_landing_bucket_files_mdss_general  = "-process_landing_bucket_files_mdss_general-dlq"
    process_landing_bucket_files_mdss_ho       = "-process_landing_bucket_files_mdss_ho-dlq"
    process_landing_bucket_files_mdss_specials = "-process_landing_bucket_files_mdss_specials-dlq"

    scan                   = "-scan-dlq"
    process_fms_metadata   = "-process_fms_metadata-dlq"
    push_data_export_to_p1 = "-push_data_export_to_p1-dlq"
  }

  landing_dlq_redriver_config = {
    (aws_cloudwatch_metric_alarm.sqs_dlq_has_messages[
      "process_landing_bucket_files_fms_general_dlq"
    ].alarm_name) = {
      feed              = "fms"
      order_type        = "general"
      source_queue_name = trimsuffix(
        local.live_feed_dlq_names.process_landing_bucket_files_fms_general,
        "-dlq"
      )
      dlq_queue_name = (
        local.live_feed_dlq_names.process_landing_bucket_files_fms_general
      )
      log_group_name = "/aws/lambda/process_landing_bucket_files_fms_general"
    }

    (aws_cloudwatch_metric_alarm.sqs_dlq_has_messages[
      "process_landing_bucket_files_fms_ho_dlq"
    ].alarm_name) = {
      feed              = "fms"
      order_type        = "ho"
      source_queue_name = trimsuffix(
        local.live_feed_dlq_names.process_landing_bucket_files_fms_ho,
        "-dlq"
      )
      dlq_queue_name = (
        local.live_feed_dlq_names.process_landing_bucket_files_fms_ho
      )
      log_group_name = "/aws/lambda/process_landing_bucket_files_fms_ho"
    }

    (aws_cloudwatch_metric_alarm.sqs_dlq_has_messages[
      "process_landing_bucket_files_fms_specials_dlq"
    ].alarm_name) = {
      feed              = "fms"
      order_type        = "specials"
      source_queue_name = trimsuffix(
        local.live_feed_dlq_names.process_landing_bucket_files_fms_specials,
        "-dlq"
      )
      dlq_queue_name = (
        local.live_feed_dlq_names.process_landing_bucket_files_fms_specials
      )
      log_group_name = "/aws/lambda/process_landing_bucket_files_fms_specials"
    }

    (aws_cloudwatch_metric_alarm.sqs_dlq_has_messages[
      "process_landing_bucket_files_mdss_general_dlq"
    ].alarm_name) = {
      feed              = "mdss"
      order_type        = "general"
      source_queue_name = trimsuffix(
        local.live_feed_dlq_names.process_landing_bucket_files_mdss_general,
        "-dlq"
      )
      dlq_queue_name = (
        local.live_feed_dlq_names.process_landing_bucket_files_mdss_general
      )
      log_group_name = "/aws/lambda/process_landing_bucket_files_mdss_general"
    }

    (aws_cloudwatch_metric_alarm.sqs_dlq_has_messages[
      "process_landing_bucket_files_mdss_ho_dlq"
    ].alarm_name) = {
      feed              = "mdss"
      order_type        = "ho"
      source_queue_name = trimsuffix(
        local.live_feed_dlq_names.process_landing_bucket_files_mdss_ho,
        "-dlq"
      )
      dlq_queue_name = (
        local.live_feed_dlq_names.process_landing_bucket_files_mdss_ho
      )
      log_group_name = "/aws/lambda/process_landing_bucket_files_mdss_ho"
    }

    (aws_cloudwatch_metric_alarm.sqs_dlq_has_messages[
      "process_landing_bucket_files_mdss_specials_dlq"
    ].alarm_name) = {
      feed              = "mdss"
      order_type        = "specials"
      source_queue_name = trimsuffix(
        local.live_feed_dlq_names.process_landing_bucket_files_mdss_specials,
        "-dlq"
      )
      dlq_queue_name = (
        local.live_feed_dlq_names.process_landing_bucket_files_mdss_specials
      )
      log_group_name = "/aws/lambda/process_landing_bucket_files_mdss_specials"
    }
  }

  landing_dlq_redriver_queue_names = distinct(flatten([
    for _, cfg in local.landing_dlq_redriver_config : [
      cfg.source_queue_name,
      cfg.dlq_queue_name,
    ]
  ]))

  landing_dlq_redriver_queue_arns = [
    for queue_name in local.landing_dlq_redriver_queue_names :
    format(
      "arn:aws:sqs:%s:%s:%s",
      data.aws_region.current.region,
      data.aws_caller_identity.current.account_id,
      queue_name,
    )
  ]
}