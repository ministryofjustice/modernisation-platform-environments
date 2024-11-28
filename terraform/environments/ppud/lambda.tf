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
  # checkov:skip=CKV_AWS_117: "PPUD Lambda functions do not require VPC access and can run in no-VPC mode"
  count                          = local.is-production == true ? 1 : 0
  filename                       = "${path.module}/stop-instance/StopEC2Instances.zip"
  function_name                  = "stop_Lambda_Function"
  role                           = aws_iam_role.lambda_role[0].arn
  handler                        = "StopEC2Instances.lambda_handler"
  runtime                        = "python3.9"
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policy_to_lambda_role]
  reserved_concurrent_executions = 5
  code_signing_config_arn        = "arn:aws:lambda:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:code-signing-config:csc-0bafee04a642a41c1"
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_prod[0].arn
  }
  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_function" "terraform_lambda_func_start" {
  # checkov:skip=CKV_AWS_117: "PPUD Lambda functions do not require VPC access and can run in no-VPC mode"
  count                          = local.is-production == true ? 1 : 0
  filename                       = "${path.module}/start-instance/StartEC2Instances.zip"
  function_name                  = "start_Lambda_Function"
  role                           = aws_iam_role.lambda_role[0].arn
  handler                        = "StartEC2Instances.lambda_handler"
  runtime                        = "python3.9"
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policy_to_lambda_role]
  reserved_concurrent_executions = 5
  code_signing_config_arn        = "arn:aws:lambda:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:code-signing-config:csc-0bafee04a642a41c1"
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_prod[0].arn
  }
  tracing_config {
    mode = "Active"
  }
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
  source_dir  = "${path.module}/lambda_scripts/"
  output_path = "${path.module}/lambda_scripts/disable_cpu_alarm.zip"
}

data "archive_file" "zip_the_enable_alarm_code" {
  count       = local.is-production == true ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda_scripts/"
  output_path = "${path.module}/lambda_scripts/enable_cpu_alarm.zip"
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
  description         = "Runs Weekly every Monday at 05:00 am"
  schedule_expression = "cron(0 5 ? * MON *)" # Time Zone is in UTC
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
  # checkov:skip=CKV_AWS_117: "PPUD Lambda functions do not require VPC access and can run in no-VPC mode"
  count                          = local.is-production == true ? 1 : 0
  filename                       = "${path.module}/lambda_scripts/disable_cpu_alarm.zip"
  function_name                  = "disable_cpu_alarm"
  role                           = aws_iam_role.lambda_role_alarm_suppression[0].arn
  handler                        = "disable_cpu_alarm.lambda_handler"
  runtime                        = "python3.12"
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policy_alarm_suppression_to_lambda_role_alarm_suppression]
  reserved_concurrent_executions = 5
  code_signing_config_arn        = "arn:aws:lambda:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:code-signing-config:csc-0bafee04a642a41c1"
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_prod[0].arn
  }
  tracing_config {
    mode = "Active"
  }
}

# Enable CPU Alarm

resource "aws_lambda_function" "terraform_lambda_enable_cpu_alarm" {
  # checkov:skip=CKV_AWS_117: "PPUD Lambda functions do not require VPC access and can run in no-VPC mode"
  count                          = local.is-production == true ? 1 : 0
  filename                       = "${path.module}/lambda_scripts/enable_cpu_alarm.zip"
  function_name                  = "enable_cpu_alarm"
  role                           = aws_iam_role.lambda_role_alarm_suppression[0].arn
  handler                        = "enable_cpu_alarm.lambda_handler"
  runtime                        = "python3.12"
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policy_alarm_suppression_to_lambda_role_alarm_suppression]
  reserved_concurrent_executions = 5
  code_signing_config_arn        = "arn:aws:lambda:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:code-signing-config:csc-0bafee04a642a41c1"
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_prod[0].arn
  }
  tracing_config {
    mode = "Active"
  }
}

######################################################
# Lambda Function to Terminate MS Word Processes - DEV
######################################################

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda_terminate_cpu_process_dev" {
  count         = local.is-development == true ? 1 : 0
  statement_id  = "AllowCloudWatchAccess"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_terminate_cpu_process_dev[0].function_name
  principal     = "cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:*"
}

resource "aws_lambda_function" "terraform_lambda_func_terminate_cpu_process_dev" {
  # checkov:skip=CKV_AWS_117: "PPUD Lambda functions do not require VPC access and can run in no-VPC mode"
  count                          = local.is-development == true ? 1 : 0
  filename                       = "${path.module}/lambda_scripts/terminate_cpu_process_dev.zip"
  function_name                  = "terminate_cpu_process"
  role                           = aws_iam_role.lambda_role_cloudwatch_invoke_lambda_dev[0].arn
  handler                        = "terminate_cpu_process_dev.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policy_cloudwatch_invoke_lambda_to_lambda_role_cloudwatch_invoke_lambda_dev]
  reserved_concurrent_executions = 5
  code_signing_config_arn        = "arn:aws:lambda:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:code-signing-config:csc-0c7136ccff2de748f"
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_dev[0].arn
  }
  tracing_config {
    mode = "Active"
  }
}

# Archive the zip file

data "archive_file" "zip_the_terminate_cpu_process_code_dev" {
  count       = local.is-development == true ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda_scripts/"
  output_path = "${path.module}/lambda_scripts/terminate_cpu_process_dev.zip"
}

######################################################
# Lambda Function to Terminate MS Word Processes - UAT
######################################################

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda_terminate_cpu_process_uat" {
  count         = local.is-preproduction == true ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_terminate_cpu_process_uat[0].function_name
  principal     = "lambda.alarms.cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-preproduction"]}:alarm:*"
}

resource "aws_lambda_function" "terraform_lambda_func_terminate_cpu_process_uat" {
  # checkov:skip=CKV_AWS_117: "PPUD Lambda functions do not require VPC access and can run in no-VPC mode"
  count                          = local.is-preproduction == true ? 1 : 0
  filename                       = "${path.module}/lambda_scripts/terminate_cpu_process_uat.zip"
  function_name                  = "terminate_cpu_process"
  role                           = aws_iam_role.lambda_role_cloudwatch_invoke_lambda_uat[0].arn
  handler                        = "terminate_cpu_process_uat.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policy_cloudwatch_invoke_lambda_to_lambda_role_cloudwatch_invoke_lambda_uat]
  reserved_concurrent_executions = 5
  code_signing_config_arn        = "arn:aws:lambda:eu-west-2:${local.environment_management.account_ids["ppud-preproduction"]}:code-signing-config:csc-0db408c5170a8eba6"
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_uat[0].arn
  }
  tracing_config {
    mode = "Active"
  }
}

# Archive the zip file

data "archive_file" "zip_the_terminate_cpu_process_code_uat" {
  count       = local.is-preproduction == true ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda_scripts/"
  output_path = "${path.module}/lambda_scripts/terminate_cpu_process_uat.zip"
}

#######################################################
# Lambda Function to Terminate MS Word Processes - PROD
#######################################################

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda_terminate_cpu_process_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_terminate_cpu_process_prod[0].function_name
  principal     = "lambda.alarms.cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:alarm:*"
}

resource "aws_lambda_function" "terraform_lambda_func_terminate_cpu_process_prod" {
  # checkov:skip=CKV_AWS_117: "PPUD Lambda functions do not require VPC access and can run in no-VPC mode"
  count                          = local.is-production == true ? 1 : 0
  filename                       = "${path.module}/lambda_scripts/terminate_cpu_process_prod.zip"
  function_name                  = "terminate_cpu_process"
  role                           = aws_iam_role.lambda_role_cloudwatch_invoke_lambda_prod[0].arn
  handler                        = "terminate_cpu_process_prod.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policy_cloudwatch_invoke_lambda_to_lambda_role_cloudwatch_invoke_lambda_prod]
  reserved_concurrent_executions = 5
  code_signing_config_arn        = "arn:aws:lambda:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:code-signing-config:csc-0bafee04a642a41c1"
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_prod[0].arn
  }
  tracing_config {
    mode = "Active"
  }
}

# Archive the zip file

data "archive_file" "zip_the_terminate_cpu_process_code_prod" {
  count       = local.is-production == true ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda_scripts/"
  output_path = "${path.module}/lambda_scripts/terminate_cpu_process_prod.zip"
}

################################################
# Lambda Function to send CPU notification - DEV
################################################

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda_send_cpu_notification_dev" {
  count         = local.is-development == true ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_send_cpu_notification_dev[0].function_name
  principal     = "lambda.alarms.cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:alarm:*"
}

resource "aws_lambda_function" "terraform_lambda_func_send_cpu_notification_dev" {
  # checkov:skip=CKV_AWS_117: "PPUD Lambda functions do not require VPC access and can run in no-VPC mode"
  count                          = local.is-development == true ? 1 : 0
  filename                       = "${path.module}/lambda_scripts/send_cpu_notification_dev.zip"
  function_name                  = "send_cpu_notification"
  role                           = aws_iam_role.lambda_role_cloudwatch_invoke_lambda_dev[0].arn
  handler                        = "send_cpu_notification_dev.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policy_cloudwatch_invoke_lambda_to_lambda_role_cloudwatch_invoke_lambda_dev]
  reserved_concurrent_executions = 5
  code_signing_config_arn        = "arn:aws:lambda:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:code-signing-config:csc-0c7136ccff2de748f"
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_dev[0].arn
  }
  tracing_config {
    mode = "Active"
  }
}

# Archive the zip file

data "archive_file" "zip_the_send_cpu_notification_code_dev" {
  count       = local.is-development == true ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda_scripts/"
  output_path = "${path.module}/lambda_scripts/send_cpu_notification_dev.zip"
}

################################################
# Lambda Function to send CPU notification - UAT
################################################

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda_send_cpu_notification_uat" {
  count         = local.is-preproduction == true ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_send_cpu_notification_uat[0].function_name
  principal     = "lambda.alarms.cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-preproduction"]}:alarm:*"
}

resource "aws_lambda_function" "terraform_lambda_func_send_cpu_notification_uat" {
  # checkov:skip=CKV_AWS_117: "PPUD Lambda functions do not require VPC access and can run in no-VPC mode"
  count                          = local.is-preproduction == true ? 1 : 0
  filename                       = "${path.module}/lambda_scripts/send_cpu_notification_uat.zip"
  function_name                  = "send_cpu_notification"
  role                           = aws_iam_role.lambda_role_cloudwatch_invoke_lambda_uat[0].arn
  handler                        = "send_cpu_notification_uat.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policy_cloudwatch_invoke_lambda_to_lambda_role_cloudwatch_invoke_lambda_uat]
  reserved_concurrent_executions = 5
  code_signing_config_arn        = "arn:aws:lambda:eu-west-2:${local.environment_management.account_ids["ppud-preproduction"]}:code-signing-config:csc-0db408c5170a8eba6"
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_uat[0].arn
  }
  tracing_config {
    mode = "Active"
  }
}

# Archive the zip file

data "archive_file" "zip_the_send_cpu_notification_code_uat" {
  count       = local.is-preproduction == true ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda_scripts/"
  output_path = "${path.module}/lambda_scripts/send_cpu_notification_uat.zip"
}

#################################################
# Lambda Function to send CPU notification - PROD
#################################################

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda_send_cpu_notification_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_send_cpu_notification_prod[0].function_name
  principal     = "lambda.alarms.cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:alarm:*"
}

resource "aws_lambda_function" "terraform_lambda_func_send_cpu_notification_prod" {
  # checkov:skip=CKV_AWS_117: "PPUD Lambda functions do not require VPC access and can run in no-VPC mode"
  count                          = local.is-production == true ? 1 : 0
  filename                       = "${path.module}/lambda_scripts/send_cpu_notification_prod.zip"
  function_name                  = "send_cpu_notification"
  role                           = aws_iam_role.lambda_role_cloudwatch_invoke_lambda_prod[0].arn
  handler                        = "send_cpu_notification_prod.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policy_cloudwatch_invoke_lambda_to_lambda_role_cloudwatch_invoke_lambda_prod]
  reserved_concurrent_executions = 5
  code_signing_config_arn        = "arn:aws:lambda:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:code-signing-config:csc-0bafee04a642a41c1"
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_prod[0].arn
  }
  tracing_config {
    mode = "Active"
  }
}

# Archive the zip file

data "archive_file" "zip_the_send_cpu_notification_code_prod" {
  count       = local.is-production == true ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda_scripts/"
  output_path = "${path.module}/lambda_scripts/send_cpu_notification_prod.zip"
}

################################################
# Lambda Function to graph CPU Utilization - DEV
################################################

resource "aws_lambda_permission" "allow_lambda_to_query_cloudwatch_send_cpu_graph_dev" {
  count         = local.is-development == true ? 1 : 0
  statement_id  = "AllowAccesstoCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_send_cpu_graph_dev[0].function_name
  principal     = "cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:*"
}

resource "aws_lambda_function" "terraform_lambda_func_send_cpu_graph_dev" {
  # checkov:skip=CKV_AWS_117: "PPUD Lambda functions do not require VPC access and can run in no-VPC mode"
  count                          = local.is-development == true ? 1 : 0
  filename                       = "${path.module}/lambda_scripts/send_cpu_graph_dev.zip"
  function_name                  = "send_cpu_graph"
  role                           = aws_iam_role.lambda_role_cloudwatch_get_metric_data_dev[0].arn
  handler                        = "send_cpu_graph_dev.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policy_cloudwatch_get_metric_data_to_lambda_role_cloudwatch_get_metric_data_dev]
  reserved_concurrent_executions = 5
 # code_signing_config_arn        = "arn:aws:lambda:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:code-signing-config:csc-0c7136ccff2de748f"
 # dead_letter_config {
 #   target_arn = aws_sqs_queue.lambda_queue_dev[0].arn
 # }
  tracing_config {
    mode = "Active"
  }
   layers = [
#    "arn:aws:lambda:eu-west-2:770693421928:layer:Klayers-p312-numpy:8", #Publically available ARN for numpy package
#    "arn:aws:lambda:eu-west-2:770693421928:layer:Klayers-p312-pillow:1" #Publically available ARN for pillow package
     "arn:aws:lambda:eu-west-2:${data.aws_ssm_parameter.klayers_account_dev[0].value}:layer:Klayers-p312-numpy:8",
     "arn:aws:lambda:eu-west-2:${data.aws_ssm_parameter.klayers_account_dev[0].value}:layer:Klayers-p312-pillow:1",
     aws_lambda_layer_version.lambda_layer_matplotlib_dev[0].arn 
  ]
}

# Archive the zip file

data "archive_file" "zip_the_send_cpu_graph_code_dev" {
  count       = local.is-development == true ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda_scripts/"
  output_path = "${path.module}/lambda_scripts/send_cpu_graph_dev.zip"
}

# Lambda Layer for Matplotlib

resource "aws_lambda_layer_version" "lambda_layer_matplotlib_dev" {
  count               = local.is-development == true ? 1 : 0
  layer_name          = "matplotlib-layer"
  description         = "matplotlib-layer for python 3.12"
  s3_bucket           = aws_s3_bucket.moj-lambda-layers-dev[0].id
  s3_key              = "matplotlib-layer.zip"
  compatible_runtimes = ["python3.12"]
}
