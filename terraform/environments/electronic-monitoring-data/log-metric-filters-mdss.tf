resource "aws_cloudwatch_log_metric_filter" "mdss_any_error" {
  name           = "mdss-any-error"
  log_group_name = module.load_mdss_lambda.cloudwatch_log_group.name
  pattern        = "{ $.message.event = \"MDSS_FILE_FAIL\" }"

  metric_transformation {
    name      = "MdssFileFailCount"
    namespace = "EMDS/MDSS"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "mdss_type_mismatch" {
  name           = "mdss-type-mismatch"
  log_group_name = module.load_mdss_lambda.cloudwatch_log_group.name
  pattern        = "{ ($.message.event = \"MDSS_FILE_FAIL\") && ($.message.error_type = \"type_mismatch\") }"

  metric_transformation {
    name      = "MdssTypeMismatchFailCount"
    namespace = "EMDS/MDSS"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "mdss_access_denied" {
  name           = "mdss-access-denied"
  log_group_name = module.load_mdss_lambda.cloudwatch_log_group.name
  pattern        = "{ ($.message.event = \"MDSS_FILE_FAIL\") && ($.message.error_type = \"access_denied\") }"

  metric_transformation {
    name      = "MdssAccessDeniedFailCount"
    namespace = "EMDS/MDSS"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "mdss_timeout" {
  name           = "mdss-timeout"
  log_group_name = module.load_mdss_lambda.cloudwatch_log_group.name
  pattern        = "{ ($.message.event = \"MDSS_FILE_FAIL\") && ($.message.error_type = \"timeout\") }"

  metric_transformation {
    name      = "MdssTimeoutFailCount"
    namespace = "EMDS/MDSS"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "mdss_fatal_failures_structured" {
  name           = "mdss-fatal-failures"
  log_group_name = "/aws/lambda/load_mdss"
  pattern        = "{ ($.message.event = \"MDSS_FILE_FAIL\") && ($.message.error_type = \"fatal\") }"

  metric_transformation {
    name      = "MdssFatalFailCount"
    namespace = "EMDS/MDSS"
    value     = "1"
  }
}
