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

resource "aws_cloudwatch_log_metric_filter" "mdss_fatal_fail" {
  name           = "mdss-fatal-fail"
  log_group_name = module.load_mdss_lambda.cloudwatch_log_group.name
  pattern        = "{ ($.message.event = \"MDSS_FILE_FAIL\") && ($.message.error_type = \"fatal\") }"

  metric_transformation {
    name      = "MdssFatalFailCount"
    namespace = "EMDS/MDSS"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "mdss_type_mismatch_fail" {
  name           = "mdss-type-mismatch-fail"
  log_group_name = module.load_mdss_lambda.cloudwatch_log_group.name
  pattern        = "{ ($.message.event = \"MDSS_FILE_FAIL\") && ($.message.error_type = \"type_mismatch\") }"

  metric_transformation {
    name      = "MdssTypeMismatchFailCount"
    namespace = "EMDS/MDSS"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "mdss_access_denied_fail" {
  name           = "mdss-access-denied-fail"
  log_group_name = module.load_mdss_lambda.cloudwatch_log_group.name
  pattern        = "{ ($.message.event = \"MDSS_FILE_FAIL\") && ($.message.error_type = \"access_denied\") }"

  metric_transformation {
    name      = "MdssAccessDeniedFailCount"
    namespace = "EMDS/MDSS"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "mdss_timeout_fail" {
  name           = "mdss-timeout-fail"
  log_group_name = module.load_mdss_lambda.cloudwatch_log_group.name
  pattern        = "{ ($.message.event = \"MDSS_FILE_FAIL\") && ($.message.error_type = \"timeout\") }"

  metric_transformation {
    name      = "MdssTimeoutFailCount"
    namespace = "EMDS/MDSS"
    value     = "1"
  }
}
