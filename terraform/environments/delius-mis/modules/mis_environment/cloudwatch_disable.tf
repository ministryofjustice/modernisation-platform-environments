module "cloudwatch_alarms_disable" {
  source = "../modules/disable_alarms_lambda"

  lambda_function_name = "${var.account_info.application_name}-${var.env_name}-disable-alarms"

  tags = local.tags
}
