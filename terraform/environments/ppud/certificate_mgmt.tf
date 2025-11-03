###############################################################################
# Lambda Functions and Eventbridge Rules for Certificate Approaching Expiration
###############################################################################

#########################
# Development Environment
#########################

# Lambda Function to check for Certificate Expiration - DEV

resource "aws_lambda_function" "terraform_lambda_func_certificate_expiry_dev" {
  # checkov:skip=CKV_AWS_117: "PPUD Lambda functions do not require VPC access and can run in no-VPC mode"
  # checkov:skip=CKV_AWS_173: "PPUD Lambda environmental variables do not contain sensitive information"
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing not required"
  count                          = local.is-development == true ? 1 : 0
  description                    = "Function to send certificate expiry reminder emails."
  s3_bucket                      = "moj-infrastructure-dev"
  s3_key                         = "lambda/functions/certificate_expiry_dev.zip"
  function_name                  = "certificate_expiry_dev"
  role                           = aws_iam_role.lambda_role_get_certificate_dev[0].arn
  handler                        = "certificate_expiry_dev.lambda_handler"
  runtime                        = "python3.13"
  timeout                        = 30
  reserved_concurrent_executions = 5
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policies_get_certificate_dev]
  environment {
    variables = {
      EXPIRY_DAYS   = "30",
      SNS_TOPIC_ARN = "arn:aws:sns:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:ppud-dev-cw-alerts"
    }
  }
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_dev[0].arn
  }
  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda_certificates_expiry_dev" {
  count         = local.is-development == true ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_certificate_expiry_dev[0].function_name
  principal     = "lambda.alarms.cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-development"]}:alarm:*"
}

resource "aws_cloudwatch_log_group" "lambda_certificate_expiry_dev_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-development == true ? 1 : 0
  name              = "/aws/lambda/certificate_expiry_dev"
  retention_in_days = 30
}

# Eventbridge Rule for Certificate Expiration - DEV

resource "aws_cloudwatch_event_rule" "certificate_approaching_expiration_dev" {
  count         = local.is-development == true ? 1 : 0
  name          = "Certificate-Approaching-Expiration"
  description   = "PPUD certificate is approaching expiration"
  event_pattern = <<EOF
{
  "source": [ "aws.acm"],
  "detail-type": ["ACM Certificate Approaching Expiration"]
}
EOF
}

resource "aws_cloudwatch_event_target" "trigger_lambda_certificate_approaching_expiration_dev" {
  count     = local.is-development == true ? 1 : 0
  rule      = aws_cloudwatch_event_rule.certificate_approaching_expiration_dev[0].name
  target_id = "certificate_approaching_expiration_dev"
  arn       = aws_lambda_function.terraform_lambda_func_certificate_expiry_dev[0].arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_certificate_approaching_expiration_dev" {
  count         = local.is-development == true ? 1 : 0
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_certificate_expiry_dev[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.certificate_approaching_expiration_dev[0].arn
}

###########################
# Preproduction Environment
###########################

# Lambda Function to check for Certificate Expiration - UAT

resource "aws_lambda_function" "terraform_lambda_func_certificate_expiry_uat" {
  # checkov:skip=CKV_AWS_117: "PPUD Lambda functions do not require VPC access and can run in no-VPC mode"
  # checkov:skip=CKV_AWS_173: "PPUD Lambda environmental variables do not contain sensitive information"
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing not required"
  count                          = local.is-preproduction == true ? 1 : 0
  description                    = "Function to send certificate expiry reminder emails."
  s3_bucket                      = "moj-infrastructure-uat"
  s3_key                         = "lambda/functions/certificate_expiry_uat.zip"
  function_name                  = "certificate_expiry_uat"
  role                           = aws_iam_role.lambda_role_get_certificate_uat[0].arn
  handler                        = "certificate_expiry_uat.lambda_handler"
  runtime                        = "python3.13"
  timeout                        = 30
  reserved_concurrent_executions = 5
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policies_get_certificate_uat]
  environment {
    variables = {
      EXPIRY_DAYS   = "30",
      SNS_TOPIC_ARN = "arn:aws:sns:eu-west-2:${local.environment_management.account_ids["ppud-preproduction"]}:ppud-uat-cw-alerts"
    }
  }
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_uat[0].arn
  }
  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda_certificates_expiry_uat" {
  count         = local.is-preproduction == true ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_certificate_expiry_uat[0].function_name
  principal     = "lambda.alarms.cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-preproduction"]}:alarm:*"
}

resource "aws_cloudwatch_log_group" "lambda_certificate_expiry_uat_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-preproduction == true ? 1 : 0
  name              = "/aws/lambda/certificate_expiry_uat"
  retention_in_days = 30
}

# Eventbridge Rule for Certificate Expiration - UAT

resource "aws_cloudwatch_event_rule" "certificate_approaching_expiration_uat" {
  count         = local.is-preproduction == true ? 1 : 0
  name          = "Certificate-Approaching-Expiration"
  description   = "PPUD certificate is approaching expiration"
  event_pattern = <<EOF
{
  "source": [ "aws.acm"],
  "detail-type": ["ACM Certificate Approaching Expiration"]
}
EOF
}

resource "aws_cloudwatch_event_target" "trigger_lambda_certificate_approaching_expiration_uat" {
  count     = local.is-preproduction == true ? 1 : 0
  rule      = aws_cloudwatch_event_rule.certificate_approaching_expiration_uat[0].name
  target_id = "certificate_approaching_expiration_uat"
  arn       = aws_lambda_function.terraform_lambda_func_certificate_expiry_uat[0].arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_certificate_approaching_expiration_uat" {
  count         = local.is-preproduction == true ? 1 : 0
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_certificate_expiry_uat[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.certificate_approaching_expiration_uat[0].arn
}

########################
# Production Environment
########################

# Lambda Function to check for Certificate Expiration - PROD

resource "aws_lambda_function" "terraform_lambda_func_certificate_expiry_prod" {
  # checkov:skip=CKV_AWS_117: "PPUD Lambda functions do not require VPC access and can run in no-VPC mode"
  # checkov:skip=CKV_AWS_173: "PPUD Lambda environmental variables do not contain sensitive information"
  # checkov:skip=CKV_AWS_272: "PPUD Lambda code signing not required"
  count                          = local.is-production == true ? 1 : 0
  description                    = "Function to send certificate expiry reminder emails."
  s3_bucket                      = "moj-infrastructure"
  s3_key                         = "lambda/functions/certificate_expiry_prod.zip"
  function_name                  = "certificate_expiry_prod"
  role                           = aws_iam_role.lambda_role_get_certificate_prod[0].arn
  handler                        = "certificate_expiry_prod.lambda_handler"
  runtime                        = "python3.13"
  timeout                        = 30
  reserved_concurrent_executions = 5
  depends_on                     = [aws_iam_role_policy_attachment.attach_lambda_policies_get_certificate_prod]
  environment {
    variables = {
      EXPIRY_DAYS   = "30",
      SNS_TOPIC_ARN = "arn:aws:sns:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:ppud-prod-cw-alerts"
    }
  }
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_queue_prod[0].arn
  }
  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda_certificates_expiry_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_certificate_expiry_prod[0].function_name
  principal     = "lambda.alarms.cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:${local.environment_management.account_ids["ppud-production"]}:alarm:*"
}

resource "aws_cloudwatch_log_group" "lambda_certificate_expiry_prod_log_group" {
  # checkov:skip=CKV_AWS_338: "Log group is only required for 30 days."
  # checkov:skip=CKV_AWS_158: "Log group does not require KMS encryption."
  count             = local.is-production == true ? 1 : 0
  name              = "/aws/lambda/certificate_expiry_prod"
  retention_in_days = 30
}

# Eventbridge Rule for Certificate Expiration - PROD

resource "aws_cloudwatch_event_rule" "certificate_approaching_expiration_prod" {
  count         = local.is-production == true ? 1 : 0
  name          = "Certificate-Approaching-Expiration"
  description   = "PPUD certificate is approaching expiration"
  event_pattern = <<EOF
{
  "source": [ "aws.acm"],
  "detail-type": ["ACM Certificate Approaching Expiration"]
}
EOF
}

resource "aws_cloudwatch_event_target" "trigger_lambda_certificate_approaching_expiration_prod" {
  count     = local.is-production == true ? 1 : 0
  rule      = aws_cloudwatch_event_rule.certificate_approaching_expiration_prod[0].name
  target_id = "certificate_approaching_expiration_prod"
  arn       = aws_lambda_function.terraform_lambda_func_certificate_expiry_prod[0].arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_certificate_approaching_expiration_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_certificate_expiry_prod[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.certificate_approaching_expiration_prod[0].arn
}