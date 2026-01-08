resource "aws_cloudwatch_log_metric_filter" "mdss_any_error" {
  count          = local.is-development ? 0 : 1
  name           = "mdss-any-error"
  log_group_name = "/aws/lambda/load_mdss"
  pattern        = "{ $.message.event = \"MDSS_FILE_FAIL\" }"

  metric_transformation {
    name      = "MdssAnyErrorCount"
    namespace = "EMDS/MDSS"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "mdss_type_mismatch" {
  count          = local.is-development ? 0 : 1
  name           = "mdss-type-mismatch"
  log_group_name = "/aws/lambda/load_mdss"
  pattern        = "{ ($.message.event = \"MDSS_FILE_FAIL\") && ($.message.error_type = \"type_mismatch\") }"

  metric_transformation {
    name      = "MdssTypeMismatchCount"
    namespace = "EMDS/MDSS"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "mdss_access_denied" {
  count          = local.is-development ? 0 : 1
  name           = "mdss-access-denied"
  log_group_name = "/aws/lambda/load_mdss"
  pattern        = "{ ($.message.event = \"MDSS_FILE_FAIL\") && ($.message.error_type = \"access_denied\") }"

  metric_transformation {
    name      = "MdssAccessDeniedCount"
    namespace = "EMDS/MDSS"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "mdss_timeout" {
  count          = local.is-development ? 0 : 1
  name           = "mdss-timeout"
  log_group_name = "/aws/lambda/load_mdss"
  pattern        = "{ ($.message.event = \"MDSS_FILE_FAIL\") && ($.message.error_type = \"timeout\") }"

  metric_transformation {
    name      = "MdssTimeoutCount"
    namespace = "EMDS/MDSS"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "mdss_fatal_failures_structured" {
  count          = local.is-development ? 0 : 1
  name           = "mdss-fatal-failures"
  log_group_name = "/aws/lambda/load_mdss"
  pattern        = "{ ($.message.event = \"MDSS_FILE_FAIL\") && ($.message.error_type = \"fatal\") }"

  metric_transformation {
    name      = "FatalFailures"
    namespace = "EMDS/MDSS"
    value     = "1"
  }
}
