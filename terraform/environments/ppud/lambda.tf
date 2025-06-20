#######################################################################
# Lambda Functions, Permissions Statement and Zipped Archive Statements
#######################################################################

##################################################
# Lambda functions to stop and start EC2 Instances
##################################################

# Lambda Function for Stop of Instance

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

data "archive_file" "zip_the_stop_instance_code" {
  count       = local.is-production == true ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/stop-instance/"
  output_path = "${path.module}/stop-instance/StopEC2Instances.zip"
}

# Cloudwatch log group for the lambda function

resource "aws_cloudwatch_log_group" "lambda_stop_lambda_function_prod_log_group" {
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-production == true ? 1 : 0
  name              = "/aws/lambda/stop_Lambda_Function"
  retention_in_days = 365
}

# Lambda Function for Start of Instance

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

data "archive_file" "zip_the_start_instance_code" {
  count       = local.is-production == true ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/start-instance/"
  output_path = "${path.module}/start-instance/StartEC2Instances.zip"
}

# Cloudwatch log group for the lambda function

resource "aws_cloudwatch_log_group" "lambda_start_lambda_function_prod_log_group" {
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-production == true ? 1 : 0
  name              = "/aws/lambda/start_Lambda_Function"
  retention_in_days = 365
}

####################################################################
# Lambda functions to disable and enable CPU alarms over the weekend
####################################################################

# Disable CPU Alarm
# Permissions statement is in iam.tf

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

# Archive the zip file

data "archive_file" "zip_the_disable_alarm_code" {
  count       = local.is-production == true ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda_scripts/"
  output_path = "${path.module}/lambda_scripts/disable_cpu_alarm.zip"
}

# Cloudwatch log group for the lambda function

resource "aws_cloudwatch_log_group" "lambda_disable_cpu_alarm_prod_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-production == true ? 1 : 0
  name              = "/aws/lambda/disable_cpu_alarm"
  retention_in_days = 30
}

# Enable CPU Alarm
# Permissions statement is in iam.tf

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

# Archive the zip file

data "archive_file" "zip_the_enable_alarm_code" {
  count       = local.is-production == true ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda_scripts/"
  output_path = "${path.module}/lambda_scripts/enable_cpu_alarm.zip"
}

# Cloudwatch log group for the lambda function

resource "aws_cloudwatch_log_group" "lambda_enable_cpu_alarm_prod_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-production == true ? 1 : 0
  name              = "/aws/lambda/enable_cpu_alarm"
  retention_in_days = 30
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

# Cloudwatch log group for the lambda function

resource "aws_cloudwatch_log_group" "lambda_terminate_cpu_process_prod_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-production == true ? 1 : 0
  name              = "/aws/lambda/terminate_cpu_process"
  retention_in_days = 30
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

# Cloudwatch log group for the lambda function

resource "aws_cloudwatch_log_group" "lambda_send_cpu_notification_prod_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-production == true ? 1 : 0
  name              = "/aws/lambda/send_cpu_notification"
  retention_in_days = 30
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
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing temporarily disabled for maintenance purposes"
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
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_dev[0].arn
  }
  tracing_config {
    mode = "Active"
  }
  layers = [
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

#################################################
# Lambda Function to graph CPU Utilization - PROD
#################################################

resource "aws_lambda_permission" "allow_lambda_to_query_cloudwatch_send_cpu_graph_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowAccesstoCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_send_cpu_graph_prod[0].function_name
  principal     = "cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
}

resource "aws_lambda_function" "terraform_lambda_func_send_cpu_graph_prod" {
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing temporarily disabled for maintenance purposes"
  count                          = local.is-production == true ? 1 : 0
  filename                       = "${path.module}/lambda_scripts/send_cpu_graph_prod.zip"
  function_name                  = "send_cpu_graph"
  role                           = aws_iam_role.lambda_role_cloudwatch_get_metric_data_prod[0].arn
  handler                        = "send_cpu_graph_prod.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policy_cloudwatch_get_metric_data_to_lambda_role_cloudwatch_get_metric_data_prod]
  reserved_concurrent_executions = 5
  # code_signing_config_arn        = "arn:aws:lambda:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:code-signing-config:csc-0bafee04a642a41c1"
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_prod[0].arn
  }
  tracing_config {
    mode = "Active"
  }
  layers = [
    "arn:aws:lambda:eu-west-2:${data.aws_ssm_parameter.klayers_account_prod[0].value}:layer:Klayers-p312-numpy:8",
    "arn:aws:lambda:eu-west-2:${data.aws_ssm_parameter.klayers_account_prod[0].value}:layer:Klayers-p312-pillow:1",
    aws_lambda_layer_version.lambda_layer_matplotlib_prod_new[0].arn
  ]
  # VPC configuration
  vpc_config {
    subnet_ids         = [data.aws_subnet.private_subnets_b.id]
    security_group_ids = [aws_security_group.PPUD-Mail-Server[0].id]
  }
}

# Archive the zip file

data "archive_file" "zip_the_send_cpu_graph_code_prod" {
  count       = local.is-production == true ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda_scripts/"
  output_path = "${path.module}/lambda_scripts/send_cpu_graph_prod.zip"
}

# Cloudwatch log group for the lambda function

resource "aws_cloudwatch_log_group" "lambda_send_cpu_graph_prod_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-production == true ? 1 : 0
  name              = "/aws/lambda/send_cpu_graph"
  retention_in_days = 30
}


##################################################
# Lambda Function to graph PPUD Email Usage - PROD
##################################################

resource "aws_lambda_permission" "allow_lambda_to_query_cloudwatch_ppud_email_report_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowAccesstoCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_ppud_email_report_prod[0].function_name
  principal     = "cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
}

resource "aws_lambda_function" "terraform_lambda_func_ppud_email_report_prod" {
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing temporarily disabled for maintenance purposes"
  count                          = local.is-production == true ? 1 : 0
  filename                       = "${path.module}/lambda_scripts/ppud_email_report_prod.zip"
  function_name                  = "ppud_email_report"
  role                           = aws_iam_role.lambda_role_cloudwatch_get_metric_data_prod[0].arn
  handler                        = "ppud_email_report_prod.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policy_cloudwatch_get_metric_data_to_lambda_role_cloudwatch_get_metric_data_prod]
  reserved_concurrent_executions = 5
  # code_signing_config_arn        = "arn:aws:lambda:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:code-signing-config:csc-0bafee04a642a41c1"
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_prod[0].arn
  }
  tracing_config {
    mode = "Active"
  }
  layers = [
    "arn:aws:lambda:eu-west-2:${data.aws_ssm_parameter.klayers_account_prod[0].value}:layer:Klayers-p312-numpy:8",
    "arn:aws:lambda:eu-west-2:${data.aws_ssm_parameter.klayers_account_prod[0].value}:layer:Klayers-p312-pillow:1",
    aws_lambda_layer_version.lambda_layer_matplotlib_prod_new[0].arn
  ]
  # VPC configuration
  vpc_config {
    subnet_ids         = [data.aws_subnet.private_subnets_b.id]
    security_group_ids = [aws_security_group.PPUD-Mail-Server[0].id]
  }
}

# Archive the zip file

data "archive_file" "zip_the_ppud_email_report_prod" {
  count       = local.is-production == true ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda_scripts/"
  output_path = "${path.module}/lambda_scripts/ppud_email_report_prod.zip"
}

# Cloudwatch log group for the lambda function

resource "aws_cloudwatch_log_group" "lambda_ppud_email_report_prod_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-production == true ? 1 : 0
  name              = "/aws/lambda/ppud_email_report"
  retention_in_days = 30
}

###################################################
# Lambda Function to graph PPUD ELB Requests - PROD
###################################################

resource "aws_lambda_permission" "allow_lambda_to_query_cloudwatch_ppud_elb_report_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowAccesstoCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_ppud_elb_report_prod[0].function_name
  principal     = "cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
}

resource "aws_lambda_function" "terraform_lambda_func_ppud_elb_report_prod" {
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing temporarily disabled for maintenance purposes"
  count                          = local.is-production == true ? 1 : 0
  filename                       = "${path.module}/lambda_scripts/ppud_elb_report_prod.zip"
  function_name                  = "ppud_elb_report"
  role                           = aws_iam_role.lambda_role_cloudwatch_get_metric_data_prod[0].arn
  handler                        = "ppud_elb_report_prod.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policy_cloudwatch_get_metric_data_to_lambda_role_cloudwatch_get_metric_data_prod]
  reserved_concurrent_executions = 5
  # code_signing_config_arn        = "arn:aws:lambda:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:code-signing-config:csc-0bafee04a642a41c1"
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_prod[0].arn
  }
  tracing_config {
    mode = "Active"
  }
  layers = [
    "arn:aws:lambda:eu-west-2:${data.aws_ssm_parameter.klayers_account_prod[0].value}:layer:Klayers-p312-numpy:8",
    "arn:aws:lambda:eu-west-2:${data.aws_ssm_parameter.klayers_account_prod[0].value}:layer:Klayers-p312-pillow:1",
    aws_lambda_layer_version.lambda_layer_matplotlib_prod_new[0].arn
  ]
  # VPC configuration
  vpc_config {
    subnet_ids         = [data.aws_subnet.private_subnets_b.id]
    security_group_ids = [aws_security_group.PPUD-Mail-Server[0].id]
  }
}

# Archive the zip file

data "archive_file" "zip_the_ppud_elb_report_prod" {
  count       = local.is-production == true ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda_scripts/"
  output_path = "${path.module}/lambda_scripts/ppud_elb_report_prod.zip"
}

# Cloudwatch log group for the lambda function

resource "aws_cloudwatch_log_group" "lambda_ppud_elb_report_prod_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-production == true ? 1 : 0
  name              = "/aws/lambda/ppud_elb_report"
  retention_in_days = 30
}

###################################################
# Lambda Function to graph WAM ELB Requests - PROD
###################################################

resource "aws_lambda_permission" "allow_lambda_to_query_cloudwatch_wam_elb_report_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowAccesstoCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_wam_elb_report_prod[0].function_name
  principal     = "cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
}

resource "aws_lambda_function" "terraform_lambda_func_wam_elb_report_prod" {
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing temporarily disabled for maintenance purposes"
  count                          = local.is-production == true ? 1 : 0
  filename                       = "${path.module}/lambda_scripts/wam_elb_report_prod.zip"
  function_name                  = "wam_elb_report"
  role                           = aws_iam_role.lambda_role_cloudwatch_get_metric_data_prod[0].arn
  handler                        = "wam_elb_report_prod.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policy_cloudwatch_get_metric_data_to_lambda_role_cloudwatch_get_metric_data_prod]
  reserved_concurrent_executions = 5
  # code_signing_config_arn        = "arn:aws:lambda:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:code-signing-config:csc-0bafee04a642a41c1"
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_prod[0].arn
  }
  tracing_config {
    mode = "Active"
  }
  layers = [
    "arn:aws:lambda:eu-west-2:${data.aws_ssm_parameter.klayers_account_prod[0].value}:layer:Klayers-p312-numpy:8",
    "arn:aws:lambda:eu-west-2:${data.aws_ssm_parameter.klayers_account_prod[0].value}:layer:Klayers-p312-pillow:1",
    aws_lambda_layer_version.lambda_layer_matplotlib_prod_new[0].arn
  ]
  # VPC configuration
  vpc_config {
    subnet_ids         = [data.aws_subnet.private_subnets_b.id]
    security_group_ids = [aws_security_group.PPUD-Mail-Server[0].id]
  }
}

# Archive the zip file

data "archive_file" "zip_the_wam_elb_report_prod" {
  count       = local.is-production == true ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda_scripts/"
  output_path = "${path.module}/lambda_scripts/wam_elb_report_prod.zip"
}

# Cloudwatch log group for the lambda function

resource "aws_cloudwatch_log_group" "lambda_wam_elb_report_prod_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-production == true ? 1 : 0
  name              = "/aws/lambda/wam_elb_report"
  retention_in_days = 30
}

#################################################
# Lambda Function to send Disk Info Report - PROD
#################################################

resource "aws_lambda_permission" "allow_lambda_to_query_cloudwatch_disk_info_report_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowAccesstoCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_disk_info_report_prod[0].function_name
  principal     = "cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
}

resource "aws_lambda_function" "terraform_lambda_func_disk_info_report_prod" {
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing temporarily disabled for maintenance purposes"
  count                          = local.is-production == true ? 1 : 0
  filename                       = "${path.module}/lambda_scripts/disk_info_report_prod.zip"
  function_name                  = "disk_info_report"
  role                           = aws_iam_role.lambda_role_cloudwatch_get_metric_data_prod[0].arn
  handler                        = "disk_info_report_prod.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policy_cloudwatch_get_metric_data_to_lambda_role_cloudwatch_get_metric_data_prod]
  reserved_concurrent_executions = 5
  # code_signing_config_arn        = "arn:aws:lambda:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:code-signing-config:csc-0bafee04a642a41c1"
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_prod[0].arn
  }
  tracing_config {
    mode = "Active"
  }
  layers = [
    "arn:aws:lambda:eu-west-2:${data.aws_ssm_parameter.klayers_account_prod[0].value}:layer:Klayers-p312-numpy:8",
    "arn:aws:lambda:eu-west-2:${data.aws_ssm_parameter.klayers_account_prod[0].value}:layer:Klayers-p312-pillow:1",
    aws_lambda_layer_version.lambda_layer_matplotlib_prod_new[0].arn
  ]
  # VPC configuration
  vpc_config {
    subnet_ids         = [data.aws_subnet.private_subnets_b.id]
    security_group_ids = [aws_security_group.PPUD-Mail-Server[0].id]
  }
}

# Archive the zip file

data "archive_file" "zip_the_disk_info_report_code_prod" {
  count       = local.is-production == true ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda_scripts/"
  output_path = "${path.module}/lambda_scripts/disk_info_report_prod.zip"
}

# Cloudwatch log group for the lambda function

resource "aws_cloudwatch_log_group" "lambda_disk_info_report_prod_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-production == true ? 1 : 0
  name              = "/aws/lambda/disk_info_report"
  retention_in_days = 30
}

###############################################
# Lambda Function for Security Hub Report - DEV
###############################################

resource "aws_lambda_permission" "allow_lambda_to_query_securityhub_securityhub_report_dev" {
  count         = local.is-development == true ? 1 : 0
  statement_id  = "AllowAccesstoSecurityHub"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_securityhub_report_dev[0].function_name
  principal     = "securityhub.amazonaws.com"
  source_arn    = "arn:aws:securityhub:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:*"
}

resource "aws_lambda_function" "terraform_lambda_func_securityhub_report_dev" {
  # checkov:skip=CKV_AWS_117: "PPUD Lambda functions do not require VPC access and can run in no-VPC mode"
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing temporarily disabled for maintenance purposes"
  count                          = local.is-development == true ? 1 : 0
  filename                       = "${path.module}/lambda_scripts/securityhub_report_dev.zip"
  function_name                  = "securityhub_report_dev"
  role                           = aws_iam_role.lambda_role_securityhub_get_data_dev[0].arn
  handler                        = "securityhub_report_dev.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policy_securityhub_get_data_to_lambda_role_securityhub_get_data_dev]
  reserved_concurrent_executions = 5
  # code_signing_config_arn        = "arn:aws:lambda:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:code-signing-config:csc-0c7136ccff2de748f"
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_dev[0].arn
  }
  tracing_config {
    mode = "Active"
  }
}

# Archive the zip file

data "archive_file" "zip_the_securityhub_report_code_dev" {
  count       = local.is-development == true ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda_scripts/"
  output_path = "${path.module}/lambda_scripts/securityhub_report_dev.zip"
}

# Cloudwatch log group for the lambda function

resource "aws_cloudwatch_log_group" "lambda_security_hub_report_dev_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-development == true ? 1 : 0
  name              = "/aws/lambda/securityhub_report_dev"
  retention_in_days = 30
}

###############################################
# Lambda Function for Security Hub Report - UAT
###############################################

resource "aws_lambda_permission" "allow_lambda_to_query_securityhub_securityhub_report_uat" {
  count         = local.is-preproduction == true ? 1 : 0
  statement_id  = "AllowAccesstoSecurityHub"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_securityhub_report_uat[0].function_name
  principal     = "securityhub.amazonaws.com"
  source_arn    = "arn:aws:securityhub:eu-west-2:${local.environment_management.account_ids["ppud-preproduction"]}:*"
}

resource "aws_lambda_function" "terraform_lambda_func_securityhub_report_uat" {
  # checkov:skip=CKV_AWS_117: "PPUD Lambda functions do not require VPC access and can run in no-VPC mode"
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing temporarily disabled for maintenance purposes"
  count                          = local.is-preproduction == true ? 1 : 0
  filename                       = "${path.module}/lambda_scripts/securityhub_report_uat.zip"
  function_name                  = "securityhub_report_uat"
  role                           = aws_iam_role.lambda_role_securityhub_get_data_uat[0].arn
  handler                        = "securityhub_report_uat.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policy_securityhub_get_data_to_lambda_role_securityhub_get_data_uat]
  reserved_concurrent_executions = 5
  #  code_signing_config_arn        = "arn:aws:lambda:eu-west-2:${local.environment_management.account_ids["ppud-preproduction"]}:code-signing-config:csc-0db408c5170a8eba6"
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_uat[0].arn
  }
  tracing_config {
    mode = "Active"
  }
}

# Archive the zip file

data "archive_file" "zip_the_securityhub_report_code_uat" {
  count       = local.is-preproduction == true ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda_scripts/"
  output_path = "${path.module}/lambda_scripts/securityhub_report_uat.zip"
}

# Cloudwatch log group for the lambda function

resource "aws_cloudwatch_log_group" "lambda_security_hub_report_uat_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-preproduction == true ? 1 : 0
  name              = "/aws/lambda/securityhub_report_uat"
  retention_in_days = 30
}

################################################
# Lambda Function for Security Hub Report - PROD
################################################

resource "aws_lambda_permission" "allow_lambda_to_query_securityhub_securityhub_report_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowAccesstoSecurityHub"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_securityhub_report_prod[0].function_name
  principal     = "securityhub.amazonaws.com"
  source_arn    = "arn:aws:securityhub:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
}

resource "aws_lambda_function" "terraform_lambda_func_securityhub_report_prod" {
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing temporarily disabled for maintenance purposes"
  count                          = local.is-production == true ? 1 : 0
  filename                       = "${path.module}/lambda_scripts/securityhub_report_prod.zip"
  function_name                  = "securityhub_report_prod"
  role                           = aws_iam_role.lambda_role_securityhub_get_data_prod[0].arn
  handler                        = "securityhub_report_prod.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policy_securityhub_get_data_to_lambda_role_securityhub_get_data_prod]
  reserved_concurrent_executions = 5
  # code_signing_config_arn        = "arn:aws:lambda:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:code-signing-config:csc-0bafee04a642a41c1"
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_prod[0].arn
  }
  tracing_config {
    mode = "Active"
  }
  # VPC configuration
  vpc_config {
    subnet_ids         = [data.aws_subnet.private_subnets_b.id]
    security_group_ids = [aws_security_group.PPUD-Mail-Server[0].id]
  }
}

# Archive the zip file

data "archive_file" "zip_the_securityhub_report_code_prod" {
  count       = local.is-production == true ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda_scripts/"
  output_path = "${path.module}/lambda_scripts/securityhub_report_prod.zip"
}

# Cloudwatch log group for the lambda function

resource "aws_cloudwatch_log_group" "lambda_security_hub_report_prod_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-production == true ? 1 : 0
  name              = "/aws/lambda/security_hub_report"
  retention_in_days = 30
}

######################################################################
# Lambda Function to extract data for PPUD Target Response Time - PROD
######################################################################

resource "aws_lambda_permission" "allow_lambda_to_query_cloudwatch_ppud_elb_trt_data_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowAccesstoCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_ppud_elb_trt_data_prod[0].function_name
  principal     = "cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
}

resource "aws_lambda_function" "terraform_lambda_func_ppud_elb_trt_data_prod" {
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing temporarily disabled for maintenance purposes"
  count                          = local.is-production == true ? 1 : 0
  filename                       = "${path.module}/lambda_scripts/ppud_elb_trt_data_prod.zip"
  function_name                  = "ppud_elb_trt_data_prod"
  role                           = aws_iam_role.lambda_role_cloudwatch_get_metric_data_prod[0].arn
  handler                        = "ppud_elb_trt_data_prod.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policy_cloudwatch_get_metric_data_to_lambda_role_cloudwatch_get_metric_data_prod]
  reserved_concurrent_executions = 5
  # code_signing_config_arn        = "arn:aws:lambda:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:code-signing-config:csc-0bafee04a642a41c1"
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_prod[0].arn
  }
  tracing_config {
    mode = "Active"
  }
  # VPC configuration
  vpc_config {
    subnet_ids         = [data.aws_subnet.private_subnets_b.id]
    security_group_ids = [aws_security_group.PPUD-Mail-Server[0].id]
  }
}

# Archive the zip file

data "archive_file" "zip_the_ppud_elb_trt_data_prod" {
  count       = local.is-production == true ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda_scripts/"
  output_path = "${path.module}/lambda_scripts/ppud_elb_trt_data_prod.zip"
}

# Cloudwatch log group for the lambda function

resource "aws_cloudwatch_log_group" "lambda_ppud_elb_trt_data_prod_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-production == true ? 1 : 0
  name              = "/aws/lambda/ppud_elb_trt_data_prod"
  retention_in_days = 30
}

###############################################################
# Lambda Function to calculate PPUD Target Response Time - PROD
###############################################################

resource "aws_lambda_permission" "allow_lambda_to_query_cloudwatch_ppud_elb_trt_calculate_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowAccesstoCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_ppud_elb_trt_calculate_prod[0].function_name
  principal     = "cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
}

resource "aws_lambda_function" "terraform_lambda_func_ppud_elb_trt_calculate_prod" {
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing temporarily disabled for maintenance purposes"
  count                          = local.is-production == true ? 1 : 0
  filename                       = "${path.module}/lambda_scripts/ppud_elb_trt_calculate_prod.zip"
  function_name                  = "ppud_elb_trt_calculate_prod"
  role                           = aws_iam_role.lambda_role_cloudwatch_get_metric_data_prod[0].arn
  handler                        = "ppud_elb_trt_calculate_prod.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policy_cloudwatch_get_metric_data_to_lambda_role_cloudwatch_get_metric_data_prod]
  reserved_concurrent_executions = 5
  # code_signing_config_arn        = "arn:aws:lambda:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:code-signing-config:csc-0bafee04a642a41c1"
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_prod[0].arn
  }
  tracing_config {
    mode = "Active"
  }
  # VPC configuration
  vpc_config {
    subnet_ids         = [data.aws_subnet.private_subnets_b.id]
    security_group_ids = [aws_security_group.PPUD-Mail-Server[0].id]
  }
}

# Archive the zip file

data "archive_file" "zip_the_ppud_elb_trt_calculate_prod" {
  count       = local.is-production == true ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda_scripts/"
  output_path = "${path.module}/lambda_scripts/ppud_elb_trt_calculate_prod.zip"
}

# Cloudwatch log group for the lambda function

resource "aws_cloudwatch_log_group" "lambda_ppud_elb_trt_calculate_prod_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-production == true ? 1 : 0
  name              = "/aws/lambda/ppud_elb_trt_calculate_prod"
  retention_in_days = 30
}

#############################################################################
# Lambda Function to extract data for PPUD load balancer target uptime - PROD
#############################################################################

resource "aws_lambda_permission" "allow_lambda_to_query_cloudwatch_ppud_elb_uptime_data_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowAccesstoCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_ppud_elb_uptime_data_prod[0].function_name
  principal     = "cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
}

resource "aws_lambda_function" "terraform_lambda_func_ppud_elb_uptime_data_prod" {
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing temporarily disabled for maintenance purposes"
  count                          = local.is-production == true ? 1 : 0
  filename                       = "${path.module}/lambda_scripts/ppud_elb_uptime_data_prod.zip"
  function_name                  = "ppud_elb_uptime_data_prod"
  role                           = aws_iam_role.lambda_role_cloudwatch_get_metric_data_prod[0].arn
  handler                        = "ppud_elb_uptime_data_prod.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policy_cloudwatch_get_metric_data_to_lambda_role_cloudwatch_get_metric_data_prod]
  reserved_concurrent_executions = 5
  # code_signing_config_arn        = "arn:aws:lambda:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:code-signing-config:csc-0bafee04a642a41c1"
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_prod[0].arn
  }
  tracing_config {
    mode = "Active"
  }
  # VPC configuration
  vpc_config {
    subnet_ids         = [data.aws_subnet.private_subnets_b.id]
    security_group_ids = [aws_security_group.PPUD-Mail-Server[0].id]
  }
}

# Archive the zip file

data "archive_file" "zip_the_ppud_elb_uptime_data_prod" {
  count       = local.is-production == true ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda_scripts/"
  output_path = "${path.module}/lambda_scripts/ppud_elb_uptime_data_prod.zip"
}

# Cloudwatch log group for the lambda function

resource "aws_cloudwatch_log_group" "lambda_ppud_elb_uptime_data_prod_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-production == true ? 1 : 0
  name              = "/aws/lambda/ppud_elb_uptime_data_prod"
  retention_in_days = 30
}

######################################################################
# Lambda Function to calculate PPUD load balancer target uptime - PROD
######################################################################

resource "aws_lambda_permission" "allow_lambda_to_query_cloudwatch_ppud_elb_uptime_calculate_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowAccesstoCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_ppud_elb_uptime_calculate_prod[0].function_name
  principal     = "cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
}

resource "aws_lambda_function" "terraform_lambda_func_ppud_elb_uptime_calculate_prod" {
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing temporarily disabled for maintenance purposes"
  count                          = local.is-production == true ? 1 : 0
  filename                       = "${path.module}/lambda_scripts/ppud_elb_uptime_calculate_prod.zip"
  function_name                  = "ppud_elb_uptime_calculate_prod"
  role                           = aws_iam_role.lambda_role_cloudwatch_get_metric_data_prod[0].arn
  handler                        = "ppud_elb_uptime_calculate_prod.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policy_cloudwatch_get_metric_data_to_lambda_role_cloudwatch_get_metric_data_prod]
  reserved_concurrent_executions = 5
  # code_signing_config_arn        = "arn:aws:lambda:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:code-signing-config:csc-0bafee04a642a41c1"
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_prod[0].arn
  }
  tracing_config {
    mode = "Active"
  }
  # VPC configuration
  vpc_config {
    subnet_ids         = [data.aws_subnet.private_subnets_b.id]
    security_group_ids = [aws_security_group.PPUD-Mail-Server[0].id]
  }
}

# Archive the zip file

data "archive_file" "zip_the_ppud_elb_uptime_calculate_prod" {
  count       = local.is-production == true ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda_scripts/"
  output_path = "${path.module}/lambda_scripts/ppud_elb_uptime_calculate_prod.zip"
}

# Cloudwatch log group for the lambda function

resource "aws_cloudwatch_log_group" "lambda_ppud_elb_uptime_calculate_prod_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-production == true ? 1 : 0
  name              = "/aws/lambda/ppud_elb_uptime_calculate_prod"
  retention_in_days = 30
}

############################################################################
# Lambda Function to graph the PPUD load balancer target respone time - PROD
############################################################################

resource "aws_lambda_function" "terraform_lambda_func_ppud_elb_trt_graph_prod" {
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing temporarily disabled for maintenance purposes"
  count                          = local.is-production == true ? 1 : 0
  s3_bucket                      = "moj-infrastructure"
  s3_key                         = "lambda/functions/ppud_elb_trt_graph_prod.zip"
  function_name                  = "ppud_elb_trt_graph_prod"
  role                           = aws_iam_role.lambda_role_cloudwatch_get_metric_data_prod[0].arn
  handler                        = "ppud_elb_trt_graph_prod.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policy_cloudwatch_get_metric_data_to_lambda_role_cloudwatch_get_metric_data_prod]
  reserved_concurrent_executions = 5
  # code_signing_config_arn        = "arn:aws:lambda:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:code-signing-config:csc-0bafee04a642a41c1"
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_prod[0].arn
  }
  tracing_config {
    mode = "Active"
  }
  layers = [
    "arn:aws:lambda:eu-west-2:${data.aws_ssm_parameter.klayers_account_prod[0].value}:layer:Klayers-p312-numpy:8",
    "arn:aws:lambda:eu-west-2:${data.aws_ssm_parameter.klayers_account_prod[0].value}:layer:Klayers-p312-pillow:1",
    aws_lambda_layer_version.lambda_layer_matplotlib_prod_new[0].arn
  ]
  # VPC configuration
  vpc_config {
    subnet_ids         = [data.aws_subnet.private_subnets_b.id]
    security_group_ids = [aws_security_group.PPUD-Mail-Server[0].id]
  }
}

# Permission statement for lambda function

resource "aws_lambda_permission" "allow_lambda_to_query_cloudwatch_ppud_elb_trt_graph_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowAccesstoCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_ppud_elb_trt_graph_prod[0].function_name
  principal     = "cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
}

# Cloudwatch log group for the lambda function

resource "aws_cloudwatch_log_group" "lambda_ppud_elb_trt_graph_prod_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-production == true ? 1 : 0
  name              = "/aws/lambda/ppud_elb_trt_graph_prod"
  retention_in_days = 30
}

############################################################################
# Lambda Function to graph the WAM load balancer target response time - PROD
############################################################################

resource "aws_lambda_function" "terraform_lambda_func_wam_elb_trt_graph_prod" {
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing temporarily disabled for maintenance purposes"
  count                          = local.is-production == true ? 1 : 0
  s3_bucket                      = "moj-infrastructure"
  s3_key                         = "lambda/functions/wam_elb_trt_graph_prod.zip"
  function_name                  = "wam_elb_trt_graph_prod"
  role                           = aws_iam_role.lambda_role_cloudwatch_get_metric_data_prod[0].arn
  handler                        = "wam_elb_trt_graph_prod.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policy_cloudwatch_get_metric_data_to_lambda_role_cloudwatch_get_metric_data_prod]
  reserved_concurrent_executions = 5
  # code_signing_config_arn        = "arn:aws:lambda:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:code-signing-config:csc-0bafee04a642a41c1"
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_prod[0].arn
  }
  tracing_config {
    mode = "Active"
  }
  layers = [
    "arn:aws:lambda:eu-west-2:${data.aws_ssm_parameter.klayers_account_prod[0].value}:layer:Klayers-p312-numpy:8",
    "arn:aws:lambda:eu-west-2:${data.aws_ssm_parameter.klayers_account_prod[0].value}:layer:Klayers-p312-pillow:1",
    aws_lambda_layer_version.lambda_layer_matplotlib_prod_new[0].arn
  ]
  # VPC configuration
  vpc_config {
    subnet_ids         = [data.aws_subnet.private_subnets_b.id]
    security_group_ids = [aws_security_group.PPUD-Mail-Server[0].id]
  }
}

# Permission statement for lambda function

resource "aws_lambda_permission" "allow_lambda_to_query_cloudwatch_wam_elb_trt_graph_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowAccesstoCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_wam_elb_trt_graph_prod[0].function_name
  principal     = "cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
}

# Cloudwatch log group for the lambda function

resource "aws_cloudwatch_log_group" "lambda_wam_elb_trt_graph_prod_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-production == true ? 1 : 0
  name              = "/aws/lambda/wam_elb_trt_graph_prod"
  retention_in_days = 30
}
