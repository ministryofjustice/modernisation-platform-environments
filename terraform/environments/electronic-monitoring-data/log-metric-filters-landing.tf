# ------------------------------------------------------------------------------
# Landing bucket processing log metric filters
#
# These filters convert structured LANDING_FILE_* logs emitted by
# process_landing_bucket_files into CloudWatch metrics.
#
# The landing processor is upstream of both live feed loaders:
# - FMS files must pass landing processing before format_json_fms_data/load_fms
# - MDSS files must pass landing processing before copy_mdss_data/load_mdss
# ------------------------------------------------------------------------------

locals {
  landing_processor_log_groups = {
    fms_general = {
      log_group_name = "/aws/lambda/process_landing_bucket_files_fms_general"
      metric_suffix  = "FmsGeneral"
    }

    fms_ho = {
      log_group_name = "/aws/lambda/process_landing_bucket_files_fms_ho"
      metric_suffix  = "FmsHo"
    }

    fms_specials = {
      log_group_name = "/aws/lambda/process_landing_bucket_files_fms_specials"
      metric_suffix  = "FmsSpecials"
    }

    mdss_general = {
      log_group_name = "/aws/lambda/process_landing_bucket_files_mdss_general"
      metric_suffix  = "MdssGeneral"
    }

    mdss_ho = {
      log_group_name = "/aws/lambda/process_landing_bucket_files_mdss_ho"
      metric_suffix  = "MdssHo"
    }

    mdss_specials = {
      log_group_name = "/aws/lambda/process_landing_bucket_files_mdss_specials"
      metric_suffix  = "MdssSpecials"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "landing_file_fail" {
  for_each = local.landing_processor_log_groups

  name           = "landing-file-fail-${each.key}"
  log_group_name = each.value.log_group_name
  pattern        = "{ $.message.event = \"LANDING_FILE_FAIL\" }"

  metric_transformation {
    name      = "LandingFileFailCount${each.value.metric_suffix}"
    namespace = "EMDS/Landing"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "landing_file_retry" {
  for_each = local.landing_processor_log_groups

  name           = "landing-file-retry-${each.key}"
  log_group_name = each.value.log_group_name
  pattern        = "{ $.message.event = \"LANDING_FILE_RETRY\" }"

  metric_transformation {
    name      = "LandingFileRetryCount${each.value.metric_suffix}"
    namespace = "EMDS/Landing"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "landing_file_ok" {
  for_each = local.landing_processor_log_groups

  name           = "landing-file-ok-${each.key}"
  log_group_name = each.value.log_group_name
  pattern        = "{ $.message.event = \"LANDING_FILE_OK\" }"

  metric_transformation {
    name      = "LandingFileOkCount${each.value.metric_suffix}"
    namespace = "EMDS/Landing"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "landing_retryable_transient_fail" {
  for_each = local.landing_processor_log_groups

  name           = "landing-retryable-transient-fail-${each.key}"
  log_group_name = each.value.log_group_name

  pattern = "{ ($.message.event = \"LANDING_FILE_FAIL\") && ($.message.error_type = \"retryable_transient\") }"

  metric_transformation {
    name      = "LandingRetryableTransientFailCount${each.value.metric_suffix}"
    namespace = "EMDS/Landing"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "landing_non_retryable_data_fail" {
  for_each = local.landing_processor_log_groups

  name           = "landing-non-retryable-data-fail-${each.key}"
  log_group_name = each.value.log_group_name

  pattern = "{ ($.message.event = \"LANDING_FILE_FAIL\") && ($.message.error_type = \"non_retryable_data\") }"

  metric_transformation {
    name      = "LandingNonRetryableDataFailCount${each.value.metric_suffix}"
    namespace = "EMDS/Landing"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "landing_non_retryable_config_fail" {
  for_each = local.landing_processor_log_groups

  name           = "landing-non-retryable-config-fail-${each.key}"
  log_group_name = each.value.log_group_name

  pattern = "{ ($.message.event = \"LANDING_FILE_FAIL\") && ($.message.error_type = \"non_retryable_config\") }"

  metric_transformation {
    name      = "LandingNonRetryableConfigFailCount${each.value.metric_suffix}"
    namespace = "EMDS/Landing"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "landing_unknown_fail" {
  for_each = local.landing_processor_log_groups

  name           = "landing-unknown-fail-${each.key}"
  log_group_name = each.value.log_group_name

  pattern = "{ ($.message.event = \"LANDING_FILE_FAIL\") && ($.message.error_type = \"unknown\") }"

  metric_transformation {
    name      = "LandingUnknownFailCount${each.value.metric_suffix}"
    namespace = "EMDS/Landing"
    value     = "1"
  }
}