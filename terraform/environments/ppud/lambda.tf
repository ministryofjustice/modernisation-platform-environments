#####################################
# Create a ZIP of Python Application
#####################################

data "archive_file" "zip_the_start_instance_code" {
  count       = local.is-production == true ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/start-instance/"
  output_path = "${path.module}/start-instance/StartEC2Instances.zip"
}

data "archive_file" "zip_the_stop_instance_code" {
  count       = local.is-production == true ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/stop-instance/"
  output_path = "${path.module}/stop-instance/StopEC2Instances.zip"
}

################################################
# Lambda Function for Stop and Start of Instance
#################################################

resource "aws_lambda_function" "terraform_lambda_func_stop" {
  count         = local.is-production == true ? 1 : 0
  filename      = "${path.module}/stop-instance/StopEC2Instances.zip"
  function_name = "stop_Lambda_Function"
  role          = aws_iam_role.lambda_role[0].arn
  handler       = "StopEC2Instances.lambda_handler"
  runtime       = "python3.9"
  depends_on    = [aws_iam_role_policy_attachment.attach_lambda_policy_to_lambda_role]
}

resource "aws_lambda_function" "terraform_lambda_func_start" {
  count         = local.is-production == true ? 1 : 0
  filename      = "${path.module}/start-instance/StartEC2Instances.zip"
  function_name = "start_Lambda_Function"
  role          = aws_iam_role.lambda_role[0].arn
  handler       = "StartEC2Instances.lambda_handler"
  runtime       = "python3.9"
  depends_on    = [aws_iam_role_policy_attachment.attach_lambda_policy_to_lambda_role]
}

########################################
# EventBridge rules to Lambda functions
########################################

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

#####################################
# Create a ZIP of Python Application
#####################################

data "archive_file" "zip_the_disable_alarm_code" {
  count       = local.is-production == true ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/disable_cpu_alarm/"
  output_path = "${path.module}/disable_cpu_alarm/disable_cpu_alarm.zip"
}

data "archive_file" "zip_the_enable_alarm_code" {
  count       = local.is-production == true ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/enable_cpu_alarm/"
  output_path = "${path.module}/enable_cpu_alarm/enable_cpu_alarm.zip"
}

########################################
# EventBridge rules to Lambda functions
########################################

# Eventbridge Rule to Disable_CPU_Alarm

resource "aws_cloudwatch_event_rule" "disable_cpu_alarm" {
  count               = local.is-production == true ? 1 : 0
  name                = "disable_cpu_alarm"
  description         = "Runs Weekly every Saturday at 00:00 am"
  schedule_expression = "cron(0 23 ? * FRI *)" # Time Zone is in UTC
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

# Eventbridge Rule to Enable_CPU_Alarm

resource "aws_cloudwatch_event_rule" "enable_cpu_alarm" {
  count               = local.is-production == true ? 1 : 0
  name                = "enable_cpu_alarm"
  description         = "Runs Weekly every Monday at 00:00 am"
  schedule_expression = "cron(0 23 ? * SUN *)" # Time Zone is in UTC
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

##################################################
# Lambda Function to Disable and Enable CPU Alarms
##################################################

# Disable CPU Alarm

resource "aws_lambda_function" "terraform_lambda_disable_cpu_alarm" {
  count         = local.is-production == true ? 1 : 0
  filename      = "${path.module}/disable_cpu_alarm/disable_cpu_alarm.zip"
  function_name = "disable_cpu_alarm"
  role          = aws_iam_role.lambda_role_alarm_suppression[0].arn
  handler       = "disable_cpu_alarm.lambda_handler"
  runtime       = "python3.12"
  depends_on    = [aws_iam_role_policy_attachment.attach_lambda_policy_alarm_suppression_to_lambda_role_alarm_suppression]
}

# Enable CPU Alarm

resource "aws_lambda_function" "terraform_lambda_enable_cpu_alarm" {
  count         = local.is-production == true ? 1 : 0
  filename      = "${path.module}/enable_cpu_alarm/enable_cpu_alarm.zip"
  function_name = "enable_cpu_alarm"
  role          = aws_iam_role.lambda_role_alarm_suppression[0].arn
  handler       = "enable_cpu_alarm.lambda_handler"
  runtime       = "python3.12"
  depends_on    = [aws_iam_role_policy_attachment.attach_lambda_policy_alarm_suppression_to_lambda_role_alarm_suppression]
}
