#######################################################################
# Lambda Functions, Permissions Statement and Zipped Archive Statements
#######################################################################

#########################
# Development Environment
#########################

######################################################
# Lambda Function to Terminate MS Word Processes - DEV
######################################################

resource "aws_lambda_function" "terraform_lambda_func_terminate_cpu_process_dev" {
  # checkov:skip=CKV_AWS_117: "PPUD Lambda functions do not require VPC access and can run in no-VPC mode"
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing not required"
  count                          = local.is-development == true ? 1 : 0
  description                    = "Function to terminate an application process due to high CPU utilisation on an EC2 instance."
  s3_bucket                      = "moj-infrastructure-dev"
  s3_key                         = "lambda/functions/terminate_cpu_process_dev.zip"
  function_name                  = "terminate_cpu_process_dev"
  role                           = aws_iam_role.lambda_role_invoke_ssm_dev[0].arn
  handler                        = "terminate_cpu_process_dev.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policies_invoke_ssm_dev]
  reserved_concurrent_executions = 5
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_dev[0].arn
  }
  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda_terminate_cpu_process_dev" {
  count         = local.is-development == true ? 1 : 0
  statement_id  = "AllowCloudWatchAccess"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_terminate_cpu_process_dev[0].function_name
  principal     = "cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:*"
}

resource "aws_cloudwatch_log_group" "lambda_terminate_cpu_process_dev_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-development == true ? 1 : 0
  name              = "/aws/lambda/terminate_cpu_process_dev"
  retention_in_days = 30
}

################################################
# Lambda Function to send CPU notification - DEV
################################################

resource "aws_lambda_function" "terraform_lambda_func_send_cpu_notification_dev" {
  # checkov:skip=CKV_AWS_117: "PPUD Lambda functions do not require VPC access and can run in no-VPC mode"
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing not required"
  count                          = local.is-development == true ? 1 : 0
  description                    = "Function to send an email notification when triggered by high CPU utilisation on an EC2 instance."
  s3_bucket                      = "moj-infrastructure-dev"
  s3_key                         = "lambda/functions/send_cpu_notification_dev.zip"
  function_name                  = "send_cpu_notification_dev"
  role                           = aws_iam_role.lambda_role_invoke_ssm_dev[0].arn
  handler                        = "send_cpu_notification_dev.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policies_invoke_ssm_dev]
  reserved_concurrent_executions = 5
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_dev[0].arn
  }
  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda_send_cpu_notification_dev" {
  count         = local.is-development == true ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_send_cpu_notification_dev[0].function_name
  principal     = "lambda.alarms.cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:alarm:*"
}

resource "aws_cloudwatch_log_group" "lambda_terminate_send_cpu_notificaion_dev_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-development == true ? 1 : 0
  name              = "/aws/lambda/send_cpu_notificaion_dev"
  retention_in_days = 30
}

################################################
# Lambda Function to graph CPU Utilization - DEV
################################################

resource "aws_lambda_function" "terraform_lambda_func_send_cpu_graph_dev" {
  # checkov:skip=CKV_AWS_117: "PPUD Lambda functions do not require VPC access and can run in no-VPC mode"
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing temporarily disabled for maintenance purposes"
  count                          = local.is-development == true ? 1 : 0
  description                    = "Function to retrieve, graph and email CPU utilisation on an EC2 instance."
  s3_bucket                      = "moj-infrastructure-dev"
  s3_key                         = "lambda/functions/send_cpu_graph_dev.zip"
  function_name                  = "send_cpu_graph_dev"
  role                           = aws_iam_role.lambda_role_get_cloudwatch_dev[0].arn
  handler                        = "send_cpu_graph_dev.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policies_get_cloudwatch_dev]
  reserved_concurrent_executions = 5
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

resource "aws_lambda_permission" "allow_lambda_to_query_cloudwatch_send_cpu_graph_dev" {
  count         = local.is-development == true ? 1 : 0
  statement_id  = "AllowAccesstoCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_send_cpu_graph_dev[0].function_name
  principal     = "cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:*"
}

resource "aws_cloudwatch_log_group" "lambda_send_cpu_graph_dev_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-development == true ? 1 : 0
  name              = "/aws/lambda/send_cpu_graph_dev"
  retention_in_days = 30
}

##################################################
# Lambda Function to analyse WAF ACL traffic - DEV
##################################################

resource "aws_lambda_function" "terraform_lambda_func_wam_waf_analysis_dev" {
  # checkov:skip=CKV_AWS_117: "PPUD Lambda functions do not require VPC access and can run in no-VPC mode"
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing temporarily disabled for maintenance purposes"
  count                          = local.is-development == true ? 1 : 0
  description                    = "Function to analyse WAM WAF ACL traffic and email a report."
  s3_bucket                      = "moj-infrastructure-dev"
  s3_key                         = "lambda/functions/wam_waf_analysis_dev.zip"
  function_name                  = "wam_waf_analysis_dev"
  role                           = aws_iam_role.lambda_role_get_cloudwatch_dev[0].arn
  handler                        = "wam_waf_analysis_dev.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policies_get_cloudwatch_dev]
  reserved_concurrent_executions = 5
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_dev[0].arn
  }
  tracing_config {
    mode = "Active"
  }
  layers = [
    "arn:aws:lambda:eu-west-2:${data.aws_ssm_parameter.klayers_account_dev[0].value}:layer:Klayers-p312-numpy:8",
    "arn:aws:lambda:eu-west-2:${data.aws_ssm_parameter.klayers_account_dev[0].value}:layer:Klayers-p312-pillow:1",   
    aws_lambda_layer_version.lambda_layer_requests_dev[0].arn,
    aws_lambda_layer_version.lambda_layer_matplotlib_dev[0].arn
  ]
}

resource "aws_lambda_permission" "allow_lambda_to_query_cloudwatch_wam_waf_analysis_dev" {
  count         = local.is-development == true ? 1 : 0
  statement_id  = "AllowAccesstoCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_wam_waf_analysis_dev[0].function_name
  principal     = "cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:*"
}

resource "aws_cloudwatch_log_group" "lambda_wam_waf_analysis_dev_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-development == true ? 1 : 0
  name              = "/aws/lambda/wam_waf_analysis_dev"
  retention_in_days = 30
}

###############################################
# Lambda Function for Security Hub Report - DEV
###############################################

resource "aws_lambda_function" "terraform_lambda_func_securityhub_report_dev" {
  # checkov:skip=CKV_AWS_117: "PPUD Lambda functions do not require VPC access and can run in no-VPC mode"
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing temporarily disabled for maintenance purposes"
  count                          = local.is-development == true ? 1 : 0
  description                    = "Function to email a summary of critical CVEs found in AWS Security Hub."
  s3_bucket                      = "moj-infrastructure-dev"
  s3_key                         = "lambda/functions/securityhub_report_dev.zip"
  function_name                  = "securityhub_report_dev"
  role                           = aws_iam_role.lambda_role_get_securityhub_data_dev[0].arn
  handler                        = "securityhub_report_dev.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policies_get_securityhub_data_dev]
  reserved_concurrent_executions = 5
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_dev[0].arn
  }
  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_permission" "allow_lambda_to_query_securityhub_securityhub_report_dev" {
  count         = local.is-development == true ? 1 : 0
  statement_id  = "AllowAccesstoSecurityHub"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_securityhub_report_dev[0].function_name
  principal     = "securityhub.amazonaws.com"
  source_arn    = "arn:aws:securityhub:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:*"
}

resource "aws_cloudwatch_log_group" "lambda_securityhub_report_dev_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-development == true ? 1 : 0
  name              = "/aws/lambda/securityhub_report_dev"
  retention_in_days = 30
}

#######################################
# Lambda Function for SES Logging - DEV
#######################################

resource "aws_lambda_function" "terraform_lambda_func_ses_logging_dev" {
  # checkov:skip=CKV_AWS_117: "PPUD Lambda functions do not require VPC access and can run in no-VPC mode"
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing temporarily disabled for maintenance purposes"
  count                          = local.is-development == true ? 1 : 0
  description                    = "Function to allow logging of outgoing emails via SES."
  s3_bucket                      = "moj-infrastructure-dev"
  s3_key                         = "lambda/functions/ses_logging_dev.zip"
  function_name                  = "ses_logging_dev"
  role                           = aws_iam_role.lambda_role_get_ses_logging_dev[0].arn
  handler                        = "ses_logging_dev.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policies_get_ses_logging_dev]
  reserved_concurrent_executions = 5
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_dev[0].arn
  }
  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_permission" "allow_sns_to_invoke_lambda_ses_logging_dev" {
  count         = local.is-development == true ? 1 : 0
  statement_id  = "AllowSNSInvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_ses_logging_dev[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.ses_logging_dev[0].arn
}

resource "aws_cloudwatch_log_group" "lambda_ses_logging_dev_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-development == true ? 1 : 0
  name              = "/aws/lambda/ses_logging_dev"
  retention_in_days = 30
}

###########################
# Preproduction Environment
###########################

######################################################
# Lambda Function to Terminate MS Word Processes - UAT
######################################################

resource "aws_lambda_function" "terraform_lambda_func_terminate_cpu_process_uat" {
  # checkov:skip=CKV_AWS_117: "PPUD Lambda functions do not require VPC access and can run in no-VPC mode"
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing not required"
  count                          = local.is-preproduction == true ? 1 : 0
  description                    = "Function to terminate an application process due to high CPU utilisation on an EC2 instance."
  s3_bucket                      = "moj-infrastructure-uat"
  s3_key                         = "lambda/functions/terminate_cpu_process_uat.zip"
  function_name                  = "terminate_cpu_process_uat"
  role                           = aws_iam_role.lambda_role_invoke_ssm_uat[0].arn
  handler                        = "terminate_cpu_process_uat.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policies_invoke_ssm_uat]
  reserved_concurrent_executions = 5
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_uat[0].arn
  }
  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda_terminate_cpu_process_uat" {
  count         = local.is-preproduction == true ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_terminate_cpu_process_uat[0].function_name
  principal     = "lambda.alarms.cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-preproduction"]}:alarm:*"
}

resource "aws_cloudwatch_log_group" "lambda_terminate_cpu_process_uat_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-preproduction == true ? 1 : 0
  name              = "/aws/lambda/terminate_cpu_process_uat"
  retention_in_days = 30
}

################################################
# Lambda Function to send CPU notification - UAT
################################################

resource "aws_lambda_function" "terraform_lambda_func_send_cpu_notification_uat" {
  # checkov:skip=CKV_AWS_117: "PPUD Lambda functions do not require VPC access and can run in no-VPC mode"
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing not required"
  count                          = local.is-preproduction == true ? 1 : 0
  description                    = "Function to send an email notification when triggered by high CPU utilisation on an EC2 instance."
	s3_bucket                      = "moj-infrastructure-uat"
  s3_key                         = "lambda/functions/send_cpu_notification_uat.zip"
  function_name                  = "send_cpu_notification_uat"
  role                           = aws_iam_role.lambda_role_invoke_ssm_uat[0].arn
  handler                        = "send_cpu_notification_uat.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policies_invoke_ssm_uat]
  reserved_concurrent_executions = 5
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_uat[0].arn
  }
  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda_send_cpu_notification_uat" {
  count         = local.is-preproduction == true ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_send_cpu_notification_uat[0].function_name
  principal     = "lambda.alarms.cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-preproduction"]}:alarm:*"
}

resource "aws_cloudwatch_log_group" "lambda_send_cpu_notification_uat_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-preproduction == true ? 1 : 0
  name              = "/aws/lambda/send_cpu_notification_uat"
  retention_in_days = 30
}

###############################################
# Lambda Function for Security Hub Report - UAT
###############################################

resource "aws_lambda_function" "terraform_lambda_func_securityhub_report_uat" {
  # checkov:skip=CKV_AWS_117: "PPUD Lambda functions do not require VPC access and can run in no-VPC mode"
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing temporarily disabled for maintenance purposes"
  count                          = local.is-preproduction == true ? 1 : 0
  description                    = "Function to email a summary of critical CVEs found in AWS Security Hub."
  s3_bucket                      = "moj-infrastructure-uat"
  s3_key                         = "lambda/functions/securityhub_report_uat.zip"
  function_name                  = "securityhub_report_uat"
  role                           = aws_iam_role.lambda_role_get_securityhub_data_uat[0].arn
  handler                        = "securityhub_report_uat.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policies_get_certificate_uat]
  reserved_concurrent_executions = 5
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_uat[0].arn
  }
  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_permission" "allow_lambda_to_query_securityhub_securityhub_report_uat" {
  count         = local.is-preproduction == true ? 1 : 0
  statement_id  = "AllowAccesstoSecurityHub"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_securityhub_report_uat[0].function_name
  principal     = "securityhub.amazonaws.com"
  source_arn    = "arn:aws:securityhub:eu-west-2:${local.environment_management.account_ids["ppud-preproduction"]}:*"
}

resource "aws_cloudwatch_log_group" "lambda_security_hub_report_uat_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-preproduction == true ? 1 : 0
  name              = "/aws/lambda/securityhub_report_uat"
  retention_in_days = 30
}

#######################################
# Lambda Function for SES Logging - UAT
#######################################

resource "aws_lambda_function" "terraform_lambda_func_ses_logging_uat" {
  # checkov:skip=CKV_AWS_117: "PPUD Lambda functions do not require VPC access and can run in no-VPC mode"
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing temporarily disabled for maintenance purposes"
  count                          = local.is-preproduction == true ? 1 : 0
  description                    = "Function to allow logging of outgoing emails via SES."
  s3_bucket                      = "moj-infrastructure-uat"
  s3_key                         = "lambda/functions/ses_logging_uat.zip"
  function_name                  = "ses_logging_uat"
  role                           = aws_iam_role.lambda_role_get_ses_logging_uat[0].arn
  handler                        = "ses_logging_uat.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policies_get_ses_logging_uat]
  reserved_concurrent_executions = 5
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_uat[0].arn
  }
  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_permission" "allow_sns_to_invoke_lambda_ses_logging_uat" {
  count         = local.is-preproduction == true ? 1 : 0
  statement_id  = "AllowSNSInvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_ses_logging_uat[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.ses_logging_uat[0].arn
}

resource "aws_cloudwatch_log_group" "lambda_ses_logging_uat_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-preproduction == true ? 1 : 0
  name              = "/aws/lambda/ses_logging_uat"
  retention_in_days = 30
}

########################
# Production Environment
########################

################################################################
# Lambda functions to disable CPU alarms over the weekend - PROD
################################################################

# Permissions statement is in iam.tf

resource "aws_lambda_function" "terraform_lambda_disable_cpu_alarm_prod" {
  # checkov:skip=CKV_AWS_117: "PPUD Lambda functions do not require VPC access and can run in no-VPC mode"
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing not required"
  count                          = local.is-production == true ? 1 : 0
  description                    = "Function to disable Cloudwatch CPU alerts."
  s3_bucket                      = "moj-infrastructure"
  s3_key                         = "lambda/functions/disable_cpu_alarm_prod.zip"
  function_name                  = "disable_cpu_alarm_prod"
  role                           = aws_iam_role.lambda_role_get_cloudwatch_prod[0].arn
  handler                        = "disable_cpu_alarm_prod.lambda_handler"
  runtime                        = "python3.12"
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policies_get_cloudwatch_prod]
  reserved_concurrent_executions = 5
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_prod[0].arn
  }
  tracing_config {
    mode = "Active"
  }
}

resource "aws_cloudwatch_log_group" "lambda_disable_cpu_alarm_prod_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-production == true ? 1 : 0
  name              = "/aws/lambda/disable_cpu_alarm_prod"
  retention_in_days = 30
}

###############################################################
# Lambda functions to enable CPU alarms over the weekend - PROD
###############################################################

# Permissions statement is in iam.tf

resource "aws_lambda_function" "terraform_lambda_enable_cpu_alarm_prod" {
  # checkov:skip=CKV_AWS_117: "PPUD Lambda functions do not require VPC access and can run in no-VPC mode"
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing not required"
  count                          = local.is-production == true ? 1 : 0
  description                    = "Function to enable Cloudwatch CPU alerts."
  s3_bucket                      = "moj-infrastructure"
  s3_key                         = "lambda/functions/enable_cpu_alarm_prod.zip"
  function_name                  = "enable_cpu_alarm_prod"
  role                           = aws_iam_role.lambda_role_get_cloudwatch_prod[0].arn
  handler                        = "enable_cpu_alarm_prod.lambda_handler"
  runtime                        = "python3.12"
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policies_get_cloudwatch_prod]
  reserved_concurrent_executions = 5
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_prod[0].arn
  }
  tracing_config {
    mode = "Active"
  }
}

resource "aws_cloudwatch_log_group" "lambda_enable_cpu_alarm_prod_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-production == true ? 1 : 0
  name              = "/aws/lambda/enable_cpu_alarm_prod"
  retention_in_days = 30
}

#######################################################
# Lambda Function to Terminate MS Word Processes - PROD
#######################################################

resource "aws_lambda_function" "terraform_lambda_func_terminate_cpu_process_prod" {
  # checkov:skip=CKV_AWS_117: "PPUD Lambda functions do not require VPC access and can run in no-VPC mode"
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing not required"
  count                          = local.is-production == true ? 1 : 0
  description                    = "Function to terminate an application process due to high CPU utilisation on an EC2 instance."
  s3_bucket                      = "moj-infrastructure"
  s3_key                         = "lambda/functions/terminate_cpu_process_prod.zip"
  function_name                  = "terminate_cpu_process_prod"
  role                           = aws_iam_role.lambda_role_invoke_ssm_prod[0].arn
  handler                        = "terminate_cpu_process_prod.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policies_invoke_ssm_prod]
  reserved_concurrent_executions = 5
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_prod[0].arn
  }
  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda_terminate_cpu_process_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_terminate_cpu_process_prod[0].function_name
  principal     = "lambda.alarms.cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:alarm:*"
}

resource "aws_cloudwatch_log_group" "lambda_terminate_cpu_process_prod_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-production == true ? 1 : 0
  name              = "/aws/lambda/terminate_cpu_process_prod"
  retention_in_days = 30
}

#################################################
# Lambda Function to send CPU notification - PROD
#################################################

resource "aws_lambda_function" "terraform_lambda_func_send_cpu_notification_prod" {
  # checkov:skip=CKV_AWS_117: "PPUD Lambda functions do not require VPC access and can run in no-VPC mode"
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing not required"
  count                          = local.is-production == true ? 1 : 0
  description                    = "Function to send an email notification when triggered by high CPU utilisation on an EC2 instance."
  s3_bucket                      = "moj-infrastructure"
  s3_key                         = "lambda/functions/send_cpu_notification_prod.zip"
  function_name                  = "send_cpu_notification_prod"
  role                           = aws_iam_role.lambda_role_invoke_ssm_prod[0].arn
  handler                        = "send_cpu_notification_prod.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policies_invoke_ssm_prod]
  reserved_concurrent_executions = 5
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_prod[0].arn
  }
  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda_send_cpu_notification_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_send_cpu_notification_prod[0].function_name
  principal     = "lambda.alarms.cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:alarm:*"
}

resource "aws_cloudwatch_log_group" "lambda_send_cpu_notification_prod_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-production == true ? 1 : 0
  name              = "/aws/lambda/send_cpu_notification_prod"
  retention_in_days = 30
}


#################################################
# Lambda Function to graph CPU Utilization - PROD
#################################################

resource "aws_lambda_function" "terraform_lambda_func_send_cpu_graph_prod" {
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing temporarily disabled for maintenance purposes"
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing not required"
  count                          = local.is-production == true ? 1 : 0
  description                    = "Function to retrieve, graph and email CPU utilisation on an EC2 instance."
  s3_bucket                      = "moj-infrastructure"
  s3_key                         = "lambda/functions/send_cpu_graph_prod.zip"
  function_name                  = "send_cpu_graph_prod"
  role                           = aws_iam_role.lambda_role_get_cloudwatch_prod[0].arn
  handler                        = "send_cpu_graph_prod.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policies_get_cloudwatch_prod]
  reserved_concurrent_executions = 5
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

resource "aws_lambda_permission" "allow_lambda_to_query_cloudwatch_send_cpu_graph_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowAccesstoCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_send_cpu_graph_prod[0].function_name
  principal     = "cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
}

resource "aws_cloudwatch_log_group" "lambda_send_cpu_graph_prod_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-production == true ? 1 : 0
  name              = "/aws/lambda/send_cpu_graph_prod"
  retention_in_days = 30
}


##################################################
# Lambda Function to graph PPUD Email Usage - PROD
##################################################

resource "aws_lambda_function" "terraform_lambda_func_ppud_email_report_prod" {
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing temporarily disabled for maintenance purposes"
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing not required"
  count                          = local.is-production == true ? 1 : 0
  description                    = "Function to analyse, graph and email the email usage on the smtp mail relays."
  s3_bucket                      = "moj-infrastructure"
  s3_key                         = "lambda/functions/ppud_email_report_prod.zip"
  function_name                  = "ppud_email_report_prod"
  role                           = aws_iam_role.lambda_role_get_cloudwatch_prod[0].arn
  handler                        = "ppud_email_report_prod.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policies_get_cloudwatch_prod]
  reserved_concurrent_executions = 5
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

resource "aws_lambda_permission" "allow_lambda_to_query_cloudwatch_ppud_email_report_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowAccesstoCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_ppud_email_report_prod[0].function_name
  principal     = "cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
}

resource "aws_cloudwatch_log_group" "lambda_ppud_email_report_prod_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-production == true ? 1 : 0
  name              = "/aws/lambda/ppud_email_report_prod"
  retention_in_days = 30
}

###################################################
# Lambda Function to graph PPUD ELB Requests - PROD
###################################################

resource "aws_lambda_function" "terraform_lambda_func_ppud_elb_report_prod" {
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing temporarily disabled for maintenance purposes"
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing not required"
  count                          = local.is-production == true ? 1 : 0
  description                    = "Function to retrieve, graph and email the utilisation of the PPUD ELB."
  s3_bucket                      = "moj-infrastructure"
  s3_key                         = "lambda/functions/ppud_elb_report_prod.zip"
  function_name                  = "ppud_elb_report_prod"
  role                           = aws_iam_role.lambda_role_get_cloudwatch_prod[0].arn
  handler                        = "ppud_elb_report_prod.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policies_get_cloudwatch_prod]
  reserved_concurrent_executions = 5
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

resource "aws_lambda_permission" "allow_lambda_to_query_cloudwatch_ppud_elb_report_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowAccesstoCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_ppud_elb_report_prod[0].function_name
  principal     = "cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
}

resource "aws_cloudwatch_log_group" "lambda_ppud_elb_report_prod_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-production == true ? 1 : 0
  name              = "/aws/lambda/ppud_elb_report_prod"
  retention_in_days = 30
}

###################################################
# Lambda Function to graph WAM ELB Requests - PROD
###################################################

resource "aws_lambda_function" "terraform_lambda_func_wam_elb_report_prod" {
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing temporarily disabled for maintenance purposes"
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing not required"
  count                          = local.is-production == true ? 1 : 0
  description                    = "Function to retrieve, graph and email the utilisation of the WAM ELB."
  s3_bucket                      = "moj-infrastructure"
  s3_key                         = "lambda/functions/wam_elb_report_prod.zip"
  function_name                  = "wam_elb_report_prod"
  role                           = aws_iam_role.lambda_role_get_cloudwatch_prod[0].arn
  handler                        = "wam_elb_report_prod.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policies_get_cloudwatch_prod]
  reserved_concurrent_executions = 5
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

resource "aws_lambda_permission" "allow_lambda_to_query_cloudwatch_wam_elb_report_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowAccesstoCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_wam_elb_report_prod[0].function_name
  principal     = "cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
}

resource "aws_cloudwatch_log_group" "lambda_wam_elb_report_prod_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-production == true ? 1 : 0
  name              = "/aws/lambda/wam_elb_report_prod"
  retention_in_days = 30
}

#################################################
# Lambda Function to send Disk Info Report - PROD
#################################################

resource "aws_lambda_function" "terraform_lambda_func_disk_info_report_prod" {
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing temporarily disabled for maintenance purposes"
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing not required"
  count                          = local.is-production == true ? 1 : 0
  description                    = "Function to retrieve, format and email a report on the disk utilisation of all Windows EC2 instances."
  s3_bucket                      = "moj-infrastructure"
  s3_key                         = "lambda/functions/disk_info_report_prod.zip"
  function_name                  = "disk_info_report_prod"
  role                           = aws_iam_role.lambda_role_get_cloudwatch_prod[0].arn
  handler                        = "disk_info_report_prod.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policies_get_cloudwatch_prod]
  reserved_concurrent_executions = 5
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

resource "aws_lambda_permission" "allow_lambda_to_query_cloudwatch_disk_info_report_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowAccesstoCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_disk_info_report_prod[0].function_name
  principal     = "cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
}

resource "aws_cloudwatch_log_group" "lambda_disk_info_report_prod_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-production == true ? 1 : 0
  name              = "/aws/lambda/disk_info_report_prod"
  retention_in_days = 30
}


################################################
# Lambda Function for Security Hub Report - PROD
################################################

resource "aws_lambda_function" "terraform_lambda_func_securityhub_report_prod" {
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing temporarily disabled for maintenance purposes"
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing not required"
  count                          = local.is-production == true ? 1 : 0
  description                    = "Function to email a summary of critical CVEs found in AWS Security Hub."
  s3_bucket                      = "moj-infrastructure"
  s3_key                         = "lambda/functions/securityhub_report_prod.zip"
  function_name                  = "securityhub_report_prod"
  role                           = aws_iam_role.lambda_role_get_securityhub_data_prod[0].arn
  handler                        = "securityhub_report_prod.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policies_get_securityhub_data_prod]
  reserved_concurrent_executions = 5
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

resource "aws_lambda_permission" "allow_lambda_to_query_securityhub_securityhub_report_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowAccesstoSecurityHub"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_securityhub_report_prod[0].function_name
  principal     = "securityhub.amazonaws.com"
  source_arn    = "arn:aws:securityhub:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
}

resource "aws_cloudwatch_log_group" "lambda_security_hub_report_prod_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-production == true ? 1 : 0
  name              = "/aws/lambda/security_hub_report_prod"
  retention_in_days = 30
}

######################################################################
# Lambda Function to extract data for PPUD Target Response Time - PROD
######################################################################

resource "aws_lambda_function" "terraform_lambda_func_ppud_elb_trt_data_prod" {
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing temporarily disabled for maintenance purposes"
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing not required"
  count                          = local.is-production == true ? 1 : 0
  description                    = "Function to retrieve PPUD ELB target response time data from Cloudwatch and send it to S3."
  s3_bucket                      = "moj-infrastructure"
  s3_key                         = "lambda/functions/ppud_elb_trt_data_prod.zip"
  function_name                  = "ppud_elb_trt_data_prod"
  role                           = aws_iam_role.lambda_role_get_elb_metrics_prod[0].arn
  handler                        = "ppud_elb_trt_data_prod.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policies_get_elb_metrics_prod]
  reserved_concurrent_executions = 5
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

resource "aws_lambda_permission" "allow_lambda_to_query_cloudwatch_ppud_elb_trt_data_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowAccesstoCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_ppud_elb_trt_data_prod[0].function_name
  principal     = "cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
}

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

resource "aws_lambda_function" "terraform_lambda_func_ppud_elb_trt_calculate_prod" {
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing temporarily disabled for maintenance purposes"
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing not required"
  count                          = local.is-production == true ? 1 : 0
  description                    = "Function to retrieve PPUD ELB target response time data from S3, calculate the monthly average target response time and email a report to end users."
  s3_bucket                      = "moj-infrastructure"
  s3_key                         = "lambda/functions/ppud_elb_trt_calculate_prod.zip"
  function_name                  = "ppud_elb_trt_calculate_prod"
  role                           = aws_iam_role.lambda_role_get_elb_metrics_prod[0].arn
  handler                        = "ppud_elb_trt_calculate_prod.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policies_get_elb_metrics_prod]
  reserved_concurrent_executions = 5
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

resource "aws_lambda_permission" "allow_lambda_to_query_cloudwatch_ppud_elb_trt_calculate_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowAccesstoCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_ppud_elb_trt_calculate_prod[0].function_name
  principal     = "cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
}

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

resource "aws_lambda_function" "terraform_lambda_func_ppud_elb_uptime_data_prod" {
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing temporarily disabled for maintenance purposes"
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing not required"
  count                          = local.is-production == true ? 1 : 0
  description                    = "Function to retrieve PPUD ELB uptime data from Cloudwatch and send it to S3."
  s3_bucket                      = "moj-infrastructure"
  s3_key                         = "lambda/functions/ppud_elb_uptime_data_prod.zip"
  function_name                  = "ppud_elb_uptime_data_prod"
  role                           = aws_iam_role.lambda_role_get_elb_metrics_prod[0].arn
  handler                        = "ppud_elb_uptime_data_prod.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policies_get_elb_metrics_prod]
  reserved_concurrent_executions = 5
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

resource "aws_lambda_permission" "allow_lambda_to_query_cloudwatch_ppud_elb_uptime_data_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowAccesstoCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_ppud_elb_uptime_data_prod[0].function_name
  principal     = "cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
}

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

resource "aws_lambda_function" "terraform_lambda_func_ppud_elb_uptime_calculate_prod" {
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing temporarily disabled for maintenance purposes"
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing not required"
  count                          = local.is-production == true ? 1 : 0
  description                    = "Function to retrieve PPUD ELB uptime data from S3, calculate the monthly average uptime and email a report to end users."
  s3_bucket                      = "moj-infrastructure"
  s3_key                         = "lambda/functions/ppud_elb_uptime_calculate_prod.zip"
  function_name                  = "ppud_elb_uptime_calculate_prod"
  role                           = aws_iam_role.lambda_role_get_elb_metrics_prod[0].arn
  handler                        = "ppud_elb_uptime_calculate_prod.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policies_get_elb_metrics_prod]
  reserved_concurrent_executions = 5
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

resource "aws_lambda_permission" "allow_lambda_to_query_cloudwatch_ppud_elb_uptime_calculate_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowAccesstoCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_ppud_elb_uptime_calculate_prod[0].function_name
  principal     = "cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
}

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
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing not required"
  count                          = local.is-production == true ? 1 : 0
  description                    = "Function to retrieve PPUD ELB daily target response time data from Cloudwatch, graph it and email it to end users."
  s3_bucket                      = "moj-infrastructure"
  s3_key                         = "lambda/functions/ppud_elb_trt_graph_prod.zip"
  function_name                  = "ppud_elb_trt_graph_prod"
  role                           = aws_iam_role.lambda_role_get_cloudwatch_prod[0].arn
  handler                        = "ppud_elb_trt_graph_prod.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policies_get_cloudwatch_prod]
  reserved_concurrent_executions = 5
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

resource "aws_lambda_permission" "allow_lambda_to_query_cloudwatch_ppud_elb_trt_graph_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowAccesstoCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_ppud_elb_trt_graph_prod[0].function_name
  principal     = "cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
}

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
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing not required"
  count                          = local.is-production == true ? 1 : 0
  description                    = "Function to retrieve WAM ELB daily target response time data from Cloudwatch, graph it and email it to end users."
  s3_bucket                      = "moj-infrastructure"
  s3_key                         = "lambda/functions/wam_elb_trt_graph_prod.zip"
  function_name                  = "wam_elb_trt_graph_prod"
  role                           = aws_iam_role.lambda_role_get_cloudwatch_prod[0].arn
  handler                        = "wam_elb_trt_graph_prod.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 300
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policies_get_cloudwatch_prod]
  reserved_concurrent_executions = 5
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

resource "aws_lambda_permission" "allow_lambda_to_query_cloudwatch_wam_elb_trt_graph_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowAccesstoCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_wam_elb_trt_graph_prod[0].function_name
  principal     = "cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
}

resource "aws_cloudwatch_log_group" "lambda_wam_elb_trt_graph_prod_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-production == true ? 1 : 0
  name              = "/aws/lambda/wam_elb_trt_graph_prod"
  retention_in_days = 30
}

#################################################################
# Lambda Function to analyse web traffic in WAM error logs - PROD
#################################################################

resource "aws_lambda_function" "terraform_lambda_func_wam_web_traffic_analysis_prod" {
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing not required"
  count                          = local.is-production == true ? 1 : 0
  description                    = "Function to analyse IIS logs from S3, format the data and output a report in Excel to S3."
  s3_bucket                      = "moj-infrastructure"
  s3_key                         = "lambda/functions/wam_web_traffic_analysis_prod.zip"
  function_name                  = "wam_web_traffic_analysis_prod"
  role                           = aws_iam_role.lambda_role_get_cloudwatch_prod[0].arn
  handler                        = "wam_web_traffic_analysis_prod.lambda_handler"
  runtime                        = "python3.12"
  timeout                        = 900
  memory_size                    = 1024
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policies_get_cloudwatch_prod]
  reserved_concurrent_executions = 5
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_prod[0].arn
  }
  tracing_config {
    mode = "Active"
  }
  layers = [
    aws_lambda_layer_version.lambda_layer_beautifulsoup_prod[0].arn,
    aws_lambda_layer_version.lambda_layer_xlsxwriter_prod[0].arn,
    aws_lambda_layer_version.lambda_layer_requests_prod[0].arn
  ]
  # VPC configuration
  vpc_config {
    subnet_ids         = [data.aws_subnet.private_subnets_b.id]
    security_group_ids = [aws_security_group.PPUD-Mail-Server[0].id]
  }
}

resource "aws_lambda_permission" "allow_lambda_to_query_cloudwatch_wam_web_traffic_analysis_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowAccesstoCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_wam_web_traffic_analysis_prod[0].function_name
  principal     = "cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:*"
}

resource "aws_cloudwatch_log_group" "lambda_wam_web_traffic_analysis_prod_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-production == true ? 1 : 0
  name              = "/aws/lambda/wam_web_traffic_analysis_prod"
  retention_in_days = 30
}
