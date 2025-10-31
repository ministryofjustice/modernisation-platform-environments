module "schedule_alarms_lambda" {
  source = "../schedule_alarms_lambda"

  count = (
    length(var.schedule_alarms_lambda.alarm_list) > 0 ||
    length(var.schedule_alarms_lambda.alarm_patterns) > 0
  ) ? 1 : 0

  lambda_function_name = "schedule-alarms"
  lambda_log_level     = var.schedule_alarms_lambda.lambda_log_level

  alarm_list     = var.schedule_alarms_lambda.alarm_list
  alarm_patterns = var.schedule_alarms_lambda.alarm_patterns

  disable_weekend = var.schedule_alarms_lambda.disable_weekend
  start_time      = var.schedule_alarms_lambda.start_time
  end_time        = var.schedule_alarms_lambda.end_time

  tags = merge(local.tags, var.schedule_alarms_lambda.tags)
}
