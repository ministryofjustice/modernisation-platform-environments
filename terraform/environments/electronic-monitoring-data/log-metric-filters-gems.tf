resource "aws_cloudwatch_log_metric_filter" "gems_file_ok" {
  name           = "gems-file-ok"
  log_group_name = module.load_gems_lambda.cloudwatch_log_group.name
  pattern        = "{ $.message.event = \"GEMS_FILE_OK\" }"

  metric_transformation {
    name      = "GemsFileOkCount"
    namespace = "EMDS/GEMS"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "gems_file_fail" {
  name           = "gems-file-fail"
  log_group_name = module.load_gems_lambda.cloudwatch_log_group.name
  pattern        = "{ $.message.event = \"GEMS_FILE_FAIL\" }"

  metric_transformation {
    name      = "GemsFileFailCount"
    namespace = "EMDS/GEMS"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "gems_retryable_transient_fail" {
  name           = "gems-retryable-transient-fail"
  log_group_name = module.load_gems_lambda.cloudwatch_log_group.name
  pattern        = "{ ($.message.event = \"GEMS_FILE_FAIL\") && ($.message.error_type = \"retryable_transient\") }"

  metric_transformation {
    name      = "GemsRetryableTransientFailCount"
    namespace = "EMDS/GEMS"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "gems_non_retryable_data_fail" {
  name           = "gems-non-retryable-data-fail"
  log_group_name = module.load_gems_lambda.cloudwatch_log_group.name
  pattern        = "{ ($.message.event = \"GEMS_FILE_FAIL\") && ($.message.error_type = \"non_retryable_data\") }"

  metric_transformation {
    name      = "GemsNonRetryableDataFailCount"
    namespace = "EMDS/GEMS"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "gems_non_retryable_config_fail" {
  name           = "gems-non-retryable-config-fail"
  log_group_name = module.load_gems_lambda.cloudwatch_log_group.name
  pattern        = "{ ($.message.event = \"GEMS_FILE_FAIL\") && ($.message.error_type = \"non_retryable_config\") }"

  metric_transformation {
    name      = "GemsNonRetryableConfigFailCount"
    namespace = "EMDS/GEMS"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "gems_unknown_fail" {
  name           = "gems-unknown-fail"
  log_group_name = module.load_gems_lambda.cloudwatch_log_group.name
  pattern        = "{ ($.message.event = \"GEMS_FILE_FAIL\") && ($.message.error_type = \"unknown\") }"

  metric_transformation {
    name      = "GemsUnknownFailCount"
    namespace = "EMDS/GEMS"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "gems_file_retry" {
  name           = "gems-file-retry"
  log_group_name = module.load_gems_lambda.cloudwatch_log_group.name
  pattern        = "{ $.message.event = \"GEMS_FILE_RETRY\" }"

  metric_transformation {
    name      = "GemsFileRetryCount"
    namespace = "EMDS/GEMS"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "gems_file_ok_after_retry" {
  name           = "gems-file-ok-after-retry"
  log_group_name = module.load_gems_lambda.cloudwatch_log_group.name
  pattern        = "{ $.message.event = \"GEMS_FILE_OK_AFTER_RETRY\" }"

  metric_transformation {
    name      = "GemsFileOkAfterRetryCount"
    namespace = "EMDS/GEMS"
    value     = "1"
  }
}