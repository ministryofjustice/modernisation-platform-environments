resource "aws_cloudwatch_log_metric_filter" "mdss_any_error" {
  name           = "mdss-any-error"
  log_group_name = "/aws/lambda/load_mdss"
  pattern        = "[ERROR]"

  metric_transformation {
    name      = "MdssAnyErrorCount"
    namespace = "EMDS/MDSS"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "mdss_type_mismatch" {
  name           = "mdss-type-mismatch"
  log_group_name = "/aws/lambda/load_mdss"
  pattern        = "TYPE_MISMATCH"

  metric_transformation {
    name      = "MdssTypeMismatchCount"
    namespace = "EMDS/MDSS"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "mdss_access_denied" {
  name           = "mdss-access-denied"
  log_group_name = "/aws/lambda/load_mdss"
  pattern        = "AccessDenied"

  metric_transformation {
    name      = "MdssAccessDeniedCount"
    namespace = "EMDS/MDSS"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "mdss_timeout" {
  name           = "mdss-timeout"
  log_group_name = "/aws/lambda/load_mdss"
  pattern        = "Task timed out"

  metric_transformation {
    name      = "MdssTimeoutCount"
    namespace = "EMDS/MDSS"
    value     = "1"
  }
}
