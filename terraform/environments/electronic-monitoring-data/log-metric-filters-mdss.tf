resource "aws_cloudwatch_log_metric_filter" "mdss_file_fail" {
  name           = "mdss-file-fail"
  log_group_name = module.load_mdss_lambda.cloudwatch_log_group.name
  pattern        = "{ $.message.event = \"MDSS_FILE_FAIL\" }"

  metric_transformation {
    name      = "MdssFileFailCount"
    namespace = "EMDS/MDSS"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "mdss_retryable_transient_fail" {
  name           = "mdss-retryable-transient-fail"
  log_group_name = module.load_mdss_lambda.cloudwatch_log_group.name
  pattern        = "{ ($.message.event = \"MDSS_FILE_FAIL\") && ($.message.error_type = \"retryable_transient\") }"

  metric_transformation {
    name      = "MdssRetryableTransientFailCount"
    namespace = "EMDS/MDSS"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "mdss_non_retryable_data_fail" {
  name           = "mdss-non-retryable-data-fail"
  log_group_name = module.load_mdss_lambda.cloudwatch_log_group.name
  pattern        = "{ ($.message.event = \"MDSS_FILE_FAIL\") && ($.message.error_type = \"non_retryable_data\") }"

  metric_transformation {
    name      = "MdssNonRetryableDataFailCount"
    namespace = "EMDS/MDSS"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "mdss_non_retryable_config_fail" {
  name           = "mdss-non-retryable-config-fail"
  log_group_name = module.load_mdss_lambda.cloudwatch_log_group.name
  pattern        = "{ ($.message.event = \"MDSS_FILE_FAIL\") && ($.message.error_type = \"non_retryable_config\") }"

  metric_transformation {
    name      = "MdssNonRetryableConfigFailCount"
    namespace = "EMDS/MDSS"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "mdss_unknown_fail" {
  name           = "mdss-unknown-fail"
  log_group_name = module.load_mdss_lambda.cloudwatch_log_group.name
  pattern        = "{ ($.message.event = \"MDSS_FILE_FAIL\") && ($.message.error_type = \"unknown\") }"

  metric_transformation {
    name      = "MdssUnknownFailCount"
    namespace = "EMDS/MDSS"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "mdss_file_retry" {
  name           = "mdss-file-retry"
  log_group_name = module.load_mdss_lambda.cloudwatch_log_group.name
  pattern        = "{ $.message.event = \"MDSS_FILE_RETRY\" }"

  metric_transformation {
    name      = "MdssFileRetryCount"
    namespace = "EMDS/MDSS"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "mdss_file_ok_after_retry" {
  name           = "mdss-file-ok-after-retry"
  log_group_name = module.load_mdss_lambda.cloudwatch_log_group.name
  pattern        = "{ $.message.event = \"MDSS_FILE_OK_AFTER_RETRY\" }"

  metric_transformation {
    name      = "MdssFileOkAfterRetryCount"
    namespace = "EMDS/MDSS"
    value     = "1"
  }
}
