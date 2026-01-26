#--Admin
resource "aws_cloudwatch_log_group" "log_group_admin" {
  name              = "${local.application_data.accounts[local.environment].app_name}-admin-ecs"
  retention_in_days = local.application_data.accounts[local.environment].admin_log_retention_days
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

resource "aws_cloudwatch_log_metric_filter" "soa_benefit_checker_rollback_error_admin" {
  name           = "SOABenefitCheckerRollbackErrorAdmin"
  pattern        = "\"<Error>\" -\"benefitchecker\" -\"<ADFC-64007>\" -\"Transaction rolledback\" -\"transaction has been rolled back\""
  log_group_name = aws_cloudwatch_log_group.log_group_admin.name

  metric_transformation {
    name      = "SOABenefitCheckerRollbackErrorAdmin"
    namespace = "CCMS-SOA-APP"
    value     = "1"
  }
}

#--Managed
resource "aws_cloudwatch_log_group" "log_group_managed" {
  name              = "${local.application_data.accounts[local.environment].app_name}-managed-ecs"
  retention_in_days = local.application_data.accounts[local.environment].managed_log_retention_days
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

resource "aws_cloudwatch_log_metric_filter" "soa_benefit_checker_rollback_error_managed" {
  name           = "SOABenefitCheckerRollbackErrorManaged"
  pattern        = "\"<Error>\" -\"benefitchecker\" -\"Transaction rolledback\" -\"transaction has been rolled back\""
  log_group_name = aws_cloudwatch_log_group.log_group_managed.name

  metric_transformation {
    name      = "SOABenefitCheckerRollbackErrorManaged"
    namespace = "CCMS-SOA-APP"
    value     = "1"
  }
}

# resource "aws_cloudwatch_log_metric_filter" "soa_custom_checks_error_managed" {
#   name           = "SOACustomChecksManaged"
#   pattern        = "\"<Local Script Error>\""
#   log_group_name = aws_cloudwatch_log_group.log_group_managed.name

#   metric_transformation {
#     name      = "SOACustomChecksManaged"
#     namespace = "CCMS-SOA-APP"
#     value     = "1"
#   }
# }

# Spilting out custom checks errors for easier alerting in Slack channel
resource "aws_cloudwatch_log_metric_filter" "soa_custom_check_test_paths" {
  name           = "SOACustomCheckTestPaths"
  pattern        = "\"<Local Script Error>\" \"failed to respond\""
  log_group_name = aws_cloudwatch_log_group.log_group_managed.name

  metric_transformation {
    name      = "SOACustomCheckTestPaths"
    namespace = "CCMS-SOA-APP"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "soa_custom_check_server_health" {
  name           = "SOACustomChecksCheckServerHealth"
  pattern        = "\"<Local Script Error>\" \"health status\""
  log_group_name = aws_cloudwatch_log_group.log_group_managed.name

  metric_transformation {
    name      = "SOACustomChecksCheckServerHealth"
    namespace = "CCMS-SOA-APP"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "soa_custom_check_percentage_heap_free_memory" {
  name           = "SOACustomCheckPercentageHeapFreeMemory"
  pattern        = "\"<Local Script Error>\" \"heap free memory\""
  log_group_name = aws_cloudwatch_log_group.log_group_managed.name

  metric_transformation {
    name      = "SOACustomCheckPercentageHeapFreeMemory"
    namespace = "CCMS-SOA-APP"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "soa_custom_check_stuck_threads" {
  name           = "SOACustomCheckStuckThreads"
  pattern        = "\"<Local Script Error>\" \"stuck threads\""
  log_group_name = aws_cloudwatch_log_group.log_group_managed.name

  metric_transformation {
    name      = "SOACustomCheckStuckThreads"
    namespace = "CCMS-SOA-APP"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "soa_custom_check_hogging_threads" {
  name           = "SOACustomCheckHoggingThreads"
  pattern        = "\"<Local Script Error>\" \"hogging threads\""
  log_group_name = aws_cloudwatch_log_group.log_group_managed.name

  metric_transformation {
    name      = "SOACustomCheckHoggingThreads"
    namespace = "CCMS-SOA-APP"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "soa_custom_check_jdbc_ebssms_state" {
  name           = "SOACustomCheckJDBCebssmsState"
  pattern        = "\"<Local Script Error>\" \"JDBC datasource state\""
  log_group_name = aws_cloudwatch_log_group.log_group_managed.name

  metric_transformation {
    name      = "SOACustomCheckJDBCebssmsState"
    namespace = "CCMS-SOA-APP"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "soa_custom_check_jdbc_failed_reserve_request_count" {
  name           = "SOACustomCheckJDBCebsState"
  pattern        = "\"<Local Script Error>\" \"JDBC datasource failedReserveRequestCount\""
  log_group_name = aws_cloudwatch_log_group.log_group_managed.name

  metric_transformation {
    name      = "SOACustomCheckJDBCebsState"
    namespace = "CCMS-SOA-APP"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_subscription_filter" "ccms_soa_edn_quiesced_filter" {
  name            = "${local.application_name}-${local.environment}-ccms-soa-edn-quiesced-filter"
  log_group_name  = aws_cloudwatch_log_group.log_group_managed.name
  filter_pattern  = "\"QUIESCING this server due to upper mark DB allocated threshold\""
  destination_arn = aws_lambda_function.ccms_soa_edn_quiesced_monitor.arn

  depends_on = [
    aws_lambda_permission.allow_cloudwatch_invoke_ccms_soa_edn_quiesced
  ]
}


#--RDS (SOA DB)
resource "aws_cloudwatch_log_group" "rds_alert" {
  name              = "/aws/rds/instance/oracle-db/alert"
  retention_in_days = local.application_data.accounts[local.environment].soa_db_log_retention_days
}

resource "aws_cloudwatch_log_group" "rds_audit" {
  name              = "/aws/rds/instance/oracle-db/audit"
  retention_in_days = local.application_data.accounts[local.environment].soa_db_log_retention_days
}

resource "aws_cloudwatch_log_group" "rds_listener" {
  name              = "/aws/rds/instance/oracle-db/listener"
  retention_in_days = local.application_data.accounts[local.environment].soa_db_log_retention_days
}

#--Alerting
resource "aws_cloudwatch_log_group" "log_group_alerting" {
  name              = "/aws/lambda/${local.application_data.accounts[local.environment].app_name}-soa-alerting"
  retention_in_days = local.application_data.accounts[local.environment].alerting_log_retention_days
}
