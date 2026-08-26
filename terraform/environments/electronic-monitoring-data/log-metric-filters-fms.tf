resource "aws_cloudwatch_log_metric_filter" "fms_file_ok" {
  name           = "fms-file-ok"
  log_group_name = module.load_fms_lambda.cloudwatch_log_group.name
  pattern        = "{ $.message.event = \"FMS_FILE_OK\" }"

  metric_transformation {
    name      = "FmsFileOkCount"
    namespace = "EMDS/FMS"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "fms_file_fail" {
  name           = "fms-file-fail"
  log_group_name = module.load_fms_lambda.cloudwatch_log_group.name
  pattern        = "{ $.message.event = \"FMS_FILE_FAIL\" }"

  metric_transformation {
    name      = "FmsFileFailCount"
    namespace = "EMDS/FMS"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "fms_file_rejected_validation" {
  name           = "fms-file-rejected-validation"
  log_group_name = module.load_fms_lambda.cloudwatch_log_group.name
  pattern        = "{ $.message.event = \"FMS_FILE_REJECTED_VALIDATION\" }"

  metric_transformation {
    name      = "FmsFileRejectedValidationCount"
    namespace = "EMDS/FMS"
    value     = "1"
  }
}