################################################
# Eventbridge Rules (to invoke Lambda functions)
################################################

# Eventbridge rule to invoke the Send CPU Graph lambda function every weekday at 17:05

resource "aws_lambda_permission" "allow_eventbridge_invoke_send_cpu_graph_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_send_cpu_graph_prod[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_schedule_send_cpu_graph_prod[0].arn
}

resource "aws_cloudwatch_event_rule" "daily_schedule_send_cpu_graph_prod" {
  count               = local.is-production == true ? 1 : 0
  name                = "send-cpu-graph-daily-weekday-schedule"
  description         = "Trigger Lambda at 17:00 UTC on weekdays"
  schedule_expression = "cron(5 17 ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda_target_send_cpu_graph_prod" {
  count     = local.is-production == true ? 1 : 0
  rule      = aws_cloudwatch_event_rule.daily_schedule_send_cpu_graph_prod[0].name
  target_id = "send_cpu_graph"
  arn       = aws_lambda_function.terraform_lambda_func_send_cpu_graph_prod[0].arn
}

# Eventbridge rule to invoke the PPUD ELB report lambda function every weekday at 20:15

resource "aws_lambda_permission" "allow_eventbridge_invoke_ppud_elb_report_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_ppud_elb_report_prod[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_schedule_ppud_elb_report_prod[0].arn
}

resource "aws_cloudwatch_event_rule" "daily_schedule_ppud_elb_report_prod" {
  count               = local.is-production == true ? 1 : 0
  name                = "ppud-elb-report-daily-weekday-schedule"
  description         = "Trigger Lambda at 20:15 UTC on weekdays"
  schedule_expression = "cron(15 20 ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda_target_ppud_elb_report_prod" {
  count     = local.is-production == true ? 1 : 0
  rule      = aws_cloudwatch_event_rule.daily_schedule_ppud_elb_report_prod[0].name
  target_id = "ppud_elb_report"
  arn       = aws_lambda_function.terraform_lambda_func_ppud_elb_report_prod[0].arn
}

# Eventbridge rule to invoke the WAM ELB report lambda function every weekday at 20:15

resource "aws_lambda_permission" "allow_eventbridge_invoke_wam_elb_report_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_wam_elb_report_prod[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_schedule_wam_elb_report_prod[0].arn
}

resource "aws_cloudwatch_event_rule" "daily_schedule_wam_elb_report_prod" {
  count               = local.is-production == true ? 1 : 0
  name                = "wam-elb-report-daily-weekday-schedule"
  description         = "Trigger Lambda at 20:15 UTC on weekdays"
  schedule_expression = "cron(15 20 ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda_target_wam_elb_report_prod" {
  count     = local.is-production == true ? 1 : 0
  rule      = aws_cloudwatch_event_rule.daily_schedule_wam_elb_report_prod[0].name
  target_id = "wam_elb_report"
  arn       = aws_lambda_function.terraform_lambda_func_wam_elb_report_prod[0].arn
}

# Eventbridge rule to invoke the PPUD Email Report lambda function every Monday at 07:00

resource "aws_lambda_permission" "allow_eventbridge_invoke_ppud_email_report_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_ppud_email_report_prod[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.weekly_schedule_ppud_email_report_prod[0].arn
}

resource "aws_cloudwatch_event_rule" "weekly_schedule_ppud_email_report_prod" {
  count               = local.is-production == true ? 1 : 0
  name                = "ppud-email-report-weekly-schedule"
  description         = "Trigger Lambda at 07:15 UTC each Monday"
  schedule_expression = "cron(15 7 ? * MON *)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda_target_ppud_email_report_prod" {
  count     = local.is-production == true ? 1 : 0
  rule      = aws_cloudwatch_event_rule.weekly_schedule_ppud_email_report_prod[0].name
  target_id = "ppud_email_report"
  arn       = aws_lambda_function.terraform_lambda_func_ppud_email_report_prod[0].arn
}

# Eventbridge rule to invoke the PPUD Disk Information Report lambda function every Monday at 07:00

resource "aws_lambda_permission" "allow_eventbridge_invoke_disk_info_report_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_disk_info_report_prod[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.weekly_schedule_disk_info_report_prod[0].arn
}

resource "aws_cloudwatch_event_rule" "weekly_schedule_disk_info_report_prod" {
  count               = local.is-production == true ? 1 : 0
  name                = "ppud-disk_info-report-weekly-schedule"
  description         = "Trigger Lambda at 07:-0 UTC each Monday"
  schedule_expression = "cron(0 7 ? * MON *)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda_target_disk_info_report_prod" {
  count     = local.is-production == true ? 1 : 0
  rule      = aws_cloudwatch_event_rule.weekly_schedule_disk_info_report_prod[0].name
  target_id = "disk_info_report"
  arn       = aws_lambda_function.terraform_lambda_func_disk_info_report_prod[0].arn
}

# Eventbridge rule to invoke the Security Hub Report Production lambda function every Monday to Friday at 07:00

resource "aws_lambda_permission" "allow_eventbridge_invoke_securityhub_report_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_securityhub_report_prod[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_schedule_securityhub_report_prod[0].arn
}

resource "aws_cloudwatch_event_rule" "daily_schedule_securityhub_report_prod" {
  count               = local.is-production == true ? 1 : 0
  name                = "securityhub-report-daily-schedule"
  description         = "Trigger Lambda at 07:00 UTC each Monday through Friday"
  schedule_expression = "cron(0 7 ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda_target_securityhub_report_prod" {
  count     = local.is-production == true ? 1 : 0
  rule      = aws_cloudwatch_event_rule.daily_schedule_securityhub_report_prod[0].name
  target_id = "securityhub_report"
  arn       = aws_lambda_function.terraform_lambda_func_securityhub_report_prod[0].arn
}

# Eventbridge rule to invoke the Security Hub Report Dev lambda function every Monday to Friday at 07:00

resource "aws_lambda_permission" "allow_eventbridge_invoke_securityhub_report_dev" {
  count         = local.is-development == true ? 1 : 0
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_securityhub_report_dev[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_schedule_securityhub_report_dev[0].arn
}

resource "aws_cloudwatch_event_rule" "daily_schedule_securityhub_report_dev" {
  count               = local.is-development == true ? 1 : 0
  name                = "securityhub-report-daily-schedule"
  description         = "Trigger Lambda at 07:00 UTC each Monday through Friday"
  schedule_expression = "cron(0 7 ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda_target_securityhub_report_dev" {
  count     = local.is-development == true ? 1 : 0
  rule      = aws_cloudwatch_event_rule.daily_schedule_securityhub_report_dev[0].name
  target_id = "securityhub_report"
  arn       = aws_lambda_function.terraform_lambda_func_securityhub_report_dev[0].arn
}

# Eventbridge rule to invoke the Security Hub Report UAT lambda function every Monday to Friday at 07:00

resource "aws_lambda_permission" "allow_eventbridge_invoke_securityhub_report_uat" {
  count         = local.is-preproduction == true ? 1 : 0
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_securityhub_report_uat[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_schedule_securityhub_report_uat[0].arn
}

resource "aws_cloudwatch_event_rule" "daily_schedule_securityhub_report_uat" {
  count               = local.is-preproduction == true ? 1 : 0
  name                = "securityhub-report-daily-schedule"
  description         = "Trigger Lambda at 07:00 UTC each Monday through Friday"
  schedule_expression = "cron(0 7 ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda_target_securityhub_report_uat" {
  count     = local.is-preproduction == true ? 1 : 0
  rule      = aws_cloudwatch_event_rule.daily_schedule_securityhub_report_uat[0].name
  target_id = "securityhub_report"
  arn       = aws_lambda_function.terraform_lambda_func_securityhub_report_uat[0].arn
}

# Eventbridge Rule to Disable CPU Alarms each Friday at 20:00

resource "aws_cloudwatch_event_rule" "disable_cpu_alarm" {
  count               = local.is-production == true ? 1 : 0
  name                = "disable_cpu_alarm"
  description         = "Runs Weekly every Friday at 20:00"
  schedule_expression = "cron(0 20 ? * FRI *)" # Time Zone is in UTC
  # schedule_expression = "cron(0 0 ? * SAT *)" # Time Zone is in UTC
}

resource "aws_cloudwatch_event_target" "trigger_lambda_disable_cpu_alarm" {
  count     = local.is-production == true ? 1 : 0
  rule      = aws_cloudwatch_event_rule.disable_cpu_alarm[0].name
  target_id = "disable_cpu_alarm"
  arn       = aws_lambda_function.terraform_lambda_disable_cpu_alarm[0].arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_disable_cpu_alarm" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_disable_cpu_alarm[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.disable_cpu_alarm[0].arn
}

# Eventbridge Rule to Enable CPU Alarms each Monday at 08:00

resource "aws_cloudwatch_event_rule" "enable_cpu_alarm" {
  count               = local.is-production == true ? 1 : 0
  name                = "enable_cpu_alarm"
  description         = "Runs Weekly every Monday at 08:00 am"
  schedule_expression = "cron(0 8 ? * MON *)" # Time Zone is in UTC
  # schedule_expression = "cron(0 0 ? * MON *)" # Time Zone is in UTC
}

resource "aws_cloudwatch_event_target" "trigger_lambda_enable_cpu_alarm" {
  count     = local.is-production == true ? 1 : 0
  rule      = aws_cloudwatch_event_rule.enable_cpu_alarm[0].name
  target_id = "enable_cpu_alarm"
  arn       = aws_lambda_function.terraform_lambda_enable_cpu_alarm[0].arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_enable_cpu_alarm" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_enable_cpu_alarm[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.enable_cpu_alarm[0].arn
}


# EventBridge Rule to stop EC2 instances

resource "aws_cloudwatch_event_rule" "stop_instance" {
  count               = local.is-production == true ? 1 : 0
  name                = "stop-instance"
  description         = "Runs Monthly on 2nd Wednesday at 00:00am GMT"
  schedule_expression = "cron(0 01 ? * 4#2 *)" # Time Zone is in UTC
}

resource "aws_cloudwatch_event_target" "trigger_lambda_monthly_once_stop" {
  count     = local.is-production == true ? 1 : 0
  rule      = aws_cloudwatch_event_rule.stop_instance[0].name
  target_id = "stop-instance"
  arn       = aws_lambda_function.terraform_lambda_func_stop[0].arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda_stop" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_stop[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop_instance[0].arn
}

# EventBridge Rule to start EC2 instances

resource "aws_cloudwatch_event_rule" "start_instance" {
  count               = local.is-production == true ? 1 : 0
  name                = "start-instance"
  description         = "Runs Monthly on 2nd Tuesday at 19:00 GMT"
  schedule_expression = "cron(0 18 ? * 3#2 *)" # Time Zone in UTC
}

resource "aws_cloudwatch_event_target" "trigger_lambda_monthly_once_start" {
  count     = local.is-production == true ? 1 : 0
  rule      = aws_cloudwatch_event_rule.start_instance[0].name
  target_id = "start-instance"
  arn       = aws_lambda_function.terraform_lambda_func_start[0].arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda_start" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_start[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start_instance[0].arn
}