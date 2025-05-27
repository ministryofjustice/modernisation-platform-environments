#--Admin
resource "aws_cloudwatch_log_group" "log_group_admin" {
  name              = "${local.application_data.accounts[local.environment].app_name}-admin-ecs"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_stream" "log_stream_admin" {
  name           = "${local.application_data.accounts[local.environment].app_name}-admin-log-stream"
  log_group_name = aws_cloudwatch_log_group.log_group_admin.name
}

resource "aws_cloudwatch_log_stream" "log_stream_admin_ecs" {
  name           = "${local.application_data.accounts[local.environment].app_name}-admin-ecs"
  log_group_name = aws_cloudwatch_log_group.log_group_admin.name
}

resource "aws_cloudwatch_log_metric_filter" "soa_stuck_thread_admin" {
  name           = "SOAStuckThreadAdmin"
  pattern        = "\"STUCK\" -\"Self tuning\""
  log_group_name = aws_cloudwatch_log_group.log_group_admin.name

  metric_transformation {
    name      = "SOAStuckThreadAdmin"
    namespace = "CCMS-SOA-APP"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "soa_benefit_checker_admin" {
  name           = "SOABenefitCheckerAdmin"
  pattern        = "\"<Error>\" \"benefitchecker\""
  log_group_name = aws_cloudwatch_log_group.log_group_admin.name

  metric_transformation {
    name      = "SOABenefitCheckerAdmin"
    namespace = "CCMS-SOA-APP"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "soa_generic_error_admin" {
  name           = "SOAGenericErrorAdmin"
  pattern        = "\"<Error>\" -\"benefitchecker\" -\"<ADFC-64007>\" -\"Transaction rolledback\" -\"transaction has been rolled back\""
  log_group_name = aws_cloudwatch_log_group.log_group_admin.name

  metric_transformation {
    name      = "SOAGenericErrorAdmin"
    namespace = "CCMS-SOA-APP"
    value     = "1"
  }
}

#--Managed
resource "aws_cloudwatch_log_group" "log_group_managed" {
  name              = "${local.application_data.accounts[local.environment].app_name}-managed-ecs"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_stream" "log_stream_managed" {
  name           = "${local.application_data.accounts[local.environment].app_name}-managed-log-stream"
  log_group_name = aws_cloudwatch_log_group.log_group_managed.name
}

resource "aws_cloudwatch_log_stream" "log_stream_managed_ecs" {
  name           = "${local.application_data.accounts[local.environment].app_name}-managed-ecs"
  log_group_name = aws_cloudwatch_log_group.log_group_managed.name
}

resource "aws_cloudwatch_log_metric_filter" "soa_stuck_thread_managed" {
  name           = "SOAStuckThreadManaged"
  pattern        = "\"STUCK\" -\"Self tuning\""
  log_group_name = aws_cloudwatch_log_group.log_group_managed.name

  metric_transformation {
    name      = "SOAStuckThreadManaged"
    namespace = "CCMS-SOA-APP"
    value     = "1"
  }
}


resource "aws_cloudwatch_log_metric_filter" "soa_benefit_checker_managed" {
  name           = "SOABenefitCheckerManaged"
  pattern        = "\"<Error>\" \"benefitchecker\""
  log_group_name = aws_cloudwatch_log_group.log_group_managed.name

  metric_transformation {
    name      = "SOABenefitCheckerManaged"
    namespace = "CCMS-SOA-APP"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "soa_generic_error_managed" {
  name           = "SOAGenericErrorManaged"
  pattern        = "\"<Error>\" -\"benefitchecker\" -\"Transaction rolledback\" -\"transaction has been rolled back\""
  log_group_name = aws_cloudwatch_log_group.log_group_managed.name

  metric_transformation {
    name      = "SOAGenericErrorManaged"
    namespace = "CCMS-SOA-APP"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "soa_custom_checks_error_managed" {
  name           = "SOACustomChecksManaged"
  pattern        = "\"<Local Script Error>\""
  log_group_name = aws_cloudwatch_log_group.log_group_managed.name

  metric_transformation {
    name      = "SOACustomChecksManaged"
    namespace = "CCMS-SOA-APP"
    value     = "1"
  }
}
