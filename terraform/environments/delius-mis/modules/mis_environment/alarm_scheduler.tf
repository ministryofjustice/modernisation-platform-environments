module "cloudwatch_alarms_schedule" {
  source = "../../../../modules/schedule_alarms_lambda"

  lambda_function_name = "${var.account_info.application_name}-${var.env_name}-schedule-alarms"
  start_time           = "20:45"
  end_time             = "06:45"
  disable_weekend      = true

  tags = local.tags
}
