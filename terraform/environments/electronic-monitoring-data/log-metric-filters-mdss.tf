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

resource "aws_cloudwatch_log_metric_filter" "mdss_reconciler_redriven_missing" {
  count          = local.is-preproduction || local.is-production ? 0 : 1
  name           = "mdss-reconciler-redriven-missing"
  log_group_name = module.mdss_reconciler[0].cloudwatch_log_group.name
  pattern        = "{ $.message.event = \"MDSS_RECONCILE_COMPLETE\" }"

  metric_transformation {
    name      = "MdssReconcilerRedrivenMissingCount"
    namespace = "EMDS/MDSS"
    value     = "$.message.redriven_missing"
  }
}

resource "aws_cloudwatch_log_metric_filter" "mdss_reconciler_redriven_stale_started" {
  count          = local.is-preproduction || local.is-production ? 0 : 1
  name           = "mdss-reconciler-redriven-stale-started"
  log_group_name = module.mdss_reconciler[0].cloudwatch_log_group.name
  pattern        = "{ $.message.event = \"MDSS_RECONCILE_COMPLETE\" }"

  metric_transformation {
    name      = "MdssReconcilerRedrivenStaleStartedCount"
    namespace = "EMDS/MDSS"
    value     = "$.message.redriven_stale_started"
  }
}

resource "aws_cloudwatch_log_metric_filter" "mdss_reconciler_redriven_failed_auto_retry" {
  count          = local.is-preproduction || local.is-production ? 0 : 1
  name           = "mdss-reconciler-redriven-failed-auto-retry"
  log_group_name = module.mdss_reconciler[0].cloudwatch_log_group.name
  pattern        = "{ $.message.event = \"MDSS_RECONCILE_COMPLETE\" }"

  metric_transformation {
    name      = "MdssReconcilerRedrivenFailedAutoRetryCount"
    namespace = "EMDS/MDSS"
    value     = "$.message.redriven_failed_auto_retry"
  }
}

resource "aws_cloudwatch_log_metric_filter" "mdss_reconciler_redriven_failed_retry_once" {
  count          = local.is-preproduction || local.is-production ? 0 : 1
  name           = "mdss-reconciler-redriven-failed-retry-once"
  log_group_name = module.mdss_reconciler[0].cloudwatch_log_group.name
  pattern        = "{ $.message.event = \"MDSS_RECONCILE_COMPLETE\" }"

  metric_transformation {
    name      = "MdssReconcilerRedrivenFailedRetryOnceCount"
    namespace = "EMDS/MDSS"
    value     = "$.message.redriven_failed_retry_once"
  }
}

resource "aws_cloudwatch_log_metric_filter" "mdss_reconciler_skipped_max_redrives" {
  count          = local.is-preproduction || local.is-production ? 0 : 1
  name           = "mdss-reconciler-skipped-max-redrives"
  log_group_name = module.mdss_reconciler[0].cloudwatch_log_group.name
  pattern        = "{ $.message.event = \"MDSS_RECONCILE_COMPLETE\" }"

  metric_transformation {
    name      = "MdssReconcilerSkippedMaxRedrivesCount"
    namespace = "EMDS/MDSS"
    value     = "$.message.skipped_max_redrives"
  }
}
