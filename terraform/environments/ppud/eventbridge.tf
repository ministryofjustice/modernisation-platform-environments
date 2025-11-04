################################################
# Eventbridge Rules (to invoke Lambda functions)
################################################

#########################
# Development Environment
#########################

# Eventbridge rule to invoke the Security Hub Report Dev lambda function every Monday to Friday at 07:00
# Set time to 07:00 during UTC and 06:00 during BST

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
  description         = "Trigger Lambda at 07:00 each Monday through Friday"
  schedule_expression = "cron(0 6 ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda_target_securityhub_report_dev" {
  count     = local.is-development == true ? 1 : 0
  rule      = aws_cloudwatch_event_rule.daily_schedule_securityhub_report_dev[0].name
  target_id = "securityhub_report"
  arn       = aws_lambda_function.terraform_lambda_func_securityhub_report_dev[0].arn
}

###########################
# Preproduction Environment
###########################

# Eventbridge rule to invoke the Security Hub Report UAT lambda function every Monday to Friday at 07:00 UTC
# Set time to 07:00 during UTC and 06:00 during BST

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
  description         = "Trigger Lambda at 07:00 each Monday through Friday"
  schedule_expression = "cron(0 6 ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda_target_securityhub_report_uat" {
  count     = local.is-preproduction == true ? 1 : 0
  rule      = aws_cloudwatch_event_rule.daily_schedule_securityhub_report_uat[0].name
  target_id = "securityhub_report"
  arn       = aws_lambda_function.terraform_lambda_func_securityhub_report_uat[0].arn
}

########################
# Production Environment
########################

# Eventbridge rule to invoke the Send CPU Graph lambda function every weekday at 17:05
# Set time to 17:05 during UTC and 16:05 during BST

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
  description         = "Trigger Lambda at 17:00 on weekdays"
  schedule_expression = "cron(5 17 ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda_target_send_cpu_graph_prod" {
  count     = local.is-production == true ? 1 : 0
  rule      = aws_cloudwatch_event_rule.daily_schedule_send_cpu_graph_prod[0].name
  target_id = "send_cpu_graph"
  arn       = aws_lambda_function.terraform_lambda_func_send_cpu_graph_prod[0].arn
}

/*
# Eventbridge rule to invoke the PPUD ELB report lambda function every weekday at 20:15
# Set time to 20:15 during UTC and 19:15 during BST

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
  description         = "Trigger Lambda at 20:15 on weekdays"
  schedule_expression = "cron(15 19 ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda_target_ppud_elb_report_prod" {
  count     = local.is-production == true ? 1 : 0
  rule      = aws_cloudwatch_event_rule.daily_schedule_ppud_elb_report_prod[0].name
  target_id = "ppud_elb_report"
  arn       = aws_lambda_function.terraform_lambda_func_ppud_elb_report_prod[0].arn
}

# Eventbridge rule to invoke the WAM ELB report lambda function every weekday at 20:15
# Set time to 20:15 during UTC and 19:15 during BST

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
  description         = "Trigger Lambda at 20:15 on weekdays"
  schedule_expression = "cron(15 19 ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda_target_wam_elb_report_prod" {
  count     = local.is-production == true ? 1 : 0
  rule      = aws_cloudwatch_event_rule.daily_schedule_wam_elb_report_prod[0].name
  target_id = "wam_elb_report"
  arn       = aws_lambda_function.terraform_lambda_func_wam_elb_report_prod[0].arn
}
*/

# Eventbridge rule to invoke the PPUD Email Report lambda function every Monday at 07:00
# Set time to 07:15 during UTC and 06:15 during BST

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
  description         = "Trigger Lambda at 07:15 each Monday"
  schedule_expression = "cron(15 6 ? * MON *)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda_target_ppud_email_report_prod" {
  count     = local.is-production == true ? 1 : 0
  rule      = aws_cloudwatch_event_rule.weekly_schedule_ppud_email_report_prod[0].name
  target_id = "ppud_email_report"
  arn       = aws_lambda_function.terraform_lambda_func_ppud_email_report_prod[0].arn
}

# Eventbridge rule to invoke the PPUD Disk Information Report lambda function every Monday at 07:00
# Set time to 07:00 during UTC and 06:00 during BST

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
  description         = "Trigger Lambda at 07:00 each Monday"
  schedule_expression = "cron(0 6 ? * MON *)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda_target_disk_info_report_prod" {
  count     = local.is-production == true ? 1 : 0
  rule      = aws_cloudwatch_event_rule.weekly_schedule_disk_info_report_prod[0].name
  target_id = "disk_info_report"
  arn       = aws_lambda_function.terraform_lambda_func_disk_info_report_prod[0].arn
}

# Eventbridge rule to invoke the Security Hub Report Production lambda function every Monday to Friday at 07:00
# Set time to 07:00 during UTC and 06:00 during BST

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
  description         = "Trigger Lambda at 07:00 each Monday through Friday"
  schedule_expression = "cron(0 6 ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda_target_securityhub_report_prod" {
  count     = local.is-production == true ? 1 : 0
  rule      = aws_cloudwatch_event_rule.daily_schedule_securityhub_report_prod[0].name
  target_id = "securityhub_report"
  arn       = aws_lambda_function.terraform_lambda_func_securityhub_report_prod[0].arn
}

# Eventbridge Rule to Disable CPU Alarms each Friday at 20:00
# Set time to 20:00 during UTC and 19:00 during BST

resource "aws_cloudwatch_event_rule" "disable_cpu_alarm_prod" {
  count               = local.is-production == true ? 1 : 0
  name                = "disable_cpu_alarm_prod"
  description         = "Runs Weekly every Friday at 20:00"
  schedule_expression = "cron(0 19 ? * FRI *)" # Time Zone is in UTC
}

resource "aws_cloudwatch_event_target" "trigger_lambda_disable_cpu_alarm_prod" {
  count     = local.is-production == true ? 1 : 0
  rule      = aws_cloudwatch_event_rule.disable_cpu_alarm_prod[0].name
  target_id = "disable_cpu_alarm_prod"
  arn       = aws_lambda_function.terraform_lambda_disable_cpu_alarm_prod[0].arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_disable_cpu_alarm_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_disable_cpu_alarm_prod[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.disable_cpu_alarm_prod[0].arn
}

# Eventbridge Rule to Enable CPU Alarms each Monday at 08:00
# Set time to 08:00 during UTC and 07:00 during BST

resource "aws_cloudwatch_event_rule" "enable_cpu_alarm_prod" {
  count               = local.is-production == true ? 1 : 0
  name                = "enable_cpu_alarm_prod"
  description         = "Runs Weekly every Monday at 08:00 am"
  schedule_expression = "cron(0 7 ? * MON *)" # Time Zone is in UTC
}

resource "aws_cloudwatch_event_target" "trigger_lambda_enable_cpu_alarm_prod" {
  count     = local.is-production == true ? 1 : 0
  rule      = aws_cloudwatch_event_rule.enable_cpu_alarm_prod[0].name
  target_id = "enable_cpu_alarm_prod"
  arn       = aws_lambda_function.terraform_lambda_enable_cpu_alarm_prod[0].arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_enable_cpu_alarm_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_enable_cpu_alarm_prod[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.enable_cpu_alarm_prod[0].arn
}

# Eventbridge rule to invoke the PPUD load balancer target uptime data lambda function every day at 00:00
# Set time to 00:00 UTC

resource "aws_lambda_permission" "allow_eventbridge_invoke_ppud_elb_uptime_data_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_ppud_elb_uptime_data_prod[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_schedule_elb_uptime_data_prod[0].arn
}

resource "aws_cloudwatch_event_rule" "daily_schedule_elb_uptime_data_prod" {
  count               = local.is-production == true ? 1 : 0
  name                = "ppud-elb-uptime-data-daily-schedule"
  description         = "Trigger Lambda at 00:00 every day"
  schedule_expression = "cron(0 0 ? * * *)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda_target_elb_uptime_data_prod" {
  count     = local.is-production == true ? 1 : 0
  rule      = aws_cloudwatch_event_rule.daily_schedule_elb_uptime_data_prod[0].name
  target_id = "ppud_elb_uptime_data_prod"
  arn       = aws_lambda_function.terraform_lambda_func_ppud_elb_uptime_data_prod[0].arn
}

# Eventbridge rule to invoke the PPUD load balancer target uptime calculation lambda function on the 1st day of every month at 02:00

resource "aws_lambda_permission" "allow_eventbridge_invoke_ppud_elb_uptime_calculate_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_ppud_elb_uptime_calculate_prod[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.monthly_schedule_elb_uptime_calculate_prod[0].arn
}

resource "aws_cloudwatch_event_rule" "monthly_schedule_elb_uptime_calculate_prod" {
  count               = local.is-production == true ? 1 : 0
  name                = "ppud-elb-uptime-calculate-monthly-schedule"
  description         = "Trigger Lambda at 02:00 on the 1st day of every month"
  schedule_expression = "cron(0 2 1 * ? *)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda_target_elb_uptime_calculate_prod" {
  count     = local.is-production == true ? 1 : 0
  rule      = aws_cloudwatch_event_rule.monthly_schedule_elb_uptime_calculate_prod[0].name
  target_id = "ppud_elb_uptime_calculate_prod"
  arn       = aws_lambda_function.terraform_lambda_func_ppud_elb_uptime_calculate_prod[0].arn
}

# Eventbridge rule to invoke the PPUD load balancer target response time lambda function every day at 00:00
# Set time to 00:00 UTC

resource "aws_lambda_permission" "allow_eventbridge_invoke_ppud_elb_trt_data_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_ppud_elb_trt_data_prod[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_schedule_elb_trt_data_prod[0].arn
}

resource "aws_cloudwatch_event_rule" "daily_schedule_elb_trt_data_prod" {
  count               = local.is-production == true ? 1 : 0
  name                = "ppud-elb-trt-data-daily-schedule"
  description         = "Trigger Lambda at 00:00 every day"
  schedule_expression = "cron(0 0 ? * * *)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda_target_elb_trt_data_prod" {
  count     = local.is-production == true ? 1 : 0
  rule      = aws_cloudwatch_event_rule.daily_schedule_elb_trt_data_prod[0].name
  target_id = "ppud_elb_trt_data_prod"
  arn       = aws_lambda_function.terraform_lambda_func_ppud_elb_trt_data_prod[0].arn
}

# Eventbridge rule to invoke the PPUD load balancer target response time calculation lambda function on the 1st day of every month at 02:00

resource "aws_lambda_permission" "allow_eventbridge_invoke_ppud_elb_trt_calculate_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_ppud_elb_trt_calculate_prod[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.monthly_schedule_elb_trt_calculate_prod[0].arn
}

resource "aws_cloudwatch_event_rule" "monthly_schedule_elb_trt_calculate_prod" {
  count               = local.is-production == true ? 1 : 0
  name                = "ppud-elb-trt-calculate-monthly-schedule"
  description         = "Trigger Lambda at 02:00 on the 1st day of every month"
  schedule_expression = "cron(0 2 1 * ? *)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda_target_elb_trt_calculate_prod" {
  count     = local.is-production == true ? 1 : 0
  rule      = aws_cloudwatch_event_rule.monthly_schedule_elb_trt_calculate_prod[0].name
  target_id = "ppud_elb_trt_calculate_prod"
  arn       = aws_lambda_function.terraform_lambda_func_ppud_elb_trt_calculate_prod[0].arn
}

# Eventbridge rule to invoke the PPUD load balancer target response time graphing lambda function every weekday at 18:00

resource "aws_lambda_permission" "allow_eventbridge_invoke_ppud_elb_trt_graph_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_ppud_elb_trt_graph_prod[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_schedule_ppud_elb_trt_graph_prod[0].arn
}

resource "aws_cloudwatch_event_rule" "daily_schedule_ppud_elb_trt_graph_prod" {
  count               = local.is-production == true ? 1 : 0
  name                = "ppud-elb-trt-graph-daily-schedule"
  description         = "Trigger Lambda at 18:00 each Monday through Friday"
  schedule_expression = "cron(0 18 ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda_target_ppud_elb_trt_graph_prod" {
  count     = local.is-production == true ? 1 : 0
  rule      = aws_cloudwatch_event_rule.daily_schedule_ppud_elb_trt_graph_prod[0].name
  target_id = "ppud_elb_trt_graph_prod"
  arn       = aws_lambda_function.terraform_lambda_func_ppud_elb_trt_graph_prod[0].arn
}

# Eventbridge rule to invoke the WAM load balancer target response time graphing lambda function every weekday at 18:00

resource "aws_lambda_permission" "allow_eventbridge_invoke_wam_elb_trt_graph_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_wam_elb_trt_graph_prod[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_schedule_wam_elb_trt_graph_prod[0].arn
}

resource "aws_cloudwatch_event_rule" "daily_schedule_wam_elb_trt_graph_prod" {
  count               = local.is-production == true ? 1 : 0
  name                = "ppud-wam-trt-graph-daily-schedule"
  description         = "Trigger Lambda at 18:00 each Monday through Friday"
  schedule_expression = "cron(0 18 ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda_target_wam_elb_trt_graph_prod" {
  count     = local.is-production == true ? 1 : 0
  rule      = aws_cloudwatch_event_rule.daily_schedule_wam_elb_trt_graph_prod[0].name
  target_id = "wam_elb_trt_graph_prod"
  arn       = aws_lambda_function.terraform_lambda_func_wam_elb_trt_graph_prod[0].arn
}

# Eventbridge rule to invoke the WAM directory traversal traffic (IIS logs) lambda function on the 15th of every month at 02:00

resource "aws_lambda_permission" "allow_eventbridge_invoke_wam_web_traffic_analysis_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_wam_web_traffic_analysis_prod[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.monthly_schedule_wam_web_traffic_analysis_prod[0].arn
}

resource "aws_cloudwatch_event_rule" "monthly_schedule_wam_web_traffic_analysis_prod" {
  count               = local.is-production == true ? 1 : 0
  name                = "wam-web-traffic-analysis-monthly-schedule"
  description         = "Trigger Lambda at 02:00 every 15th of the month."
  schedule_expression = "cron(0 2 15 * ? *)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda_target_wam_web_traffic_analysis_prod" {
  count     = local.is-production == true ? 1 : 0
  rule      = aws_cloudwatch_event_rule.monthly_schedule_wam_web_traffic_analysis_prod[0].name
  target_id = "wam_web_traffic_analysis_prod"
  arn       = aws_lambda_function.terraform_lambda_func_wam_web_traffic_analysis_prod[0].arn
}
