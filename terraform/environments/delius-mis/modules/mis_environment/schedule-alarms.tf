module "schedule_alarms" {
  count = var.environment_config.cloudwatch_alarm_schedule ? 1 : 0

  source = "../../../../modules/schedule_alarms_lambda"

  lambda_function_name = "${var.account_info.application_name}-${var.env_name}-schedule-alarms"
  start_time           = var.environment_config.cloudwatch_alarm_disable_time
  end_time             = var.environment_config.cloudwatch_alarm_enable_time
  disable_weekend      = var.environment_config.cloudwatch_alarm_disable_weekend

  tags = local.tags
}
