##############################################################################
# Lambda Function and Eventbridge Rules for Certificate Approaching Expiration
##############################################################################

# Lambda Function to check for Certificate Expiration - DEV

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda_certificates_expiry_dev" {
  count         = local.is-development == true ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_certificate_expiry_dev[0].function_name
  principal     = "lambda.alarms.cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:075585660276:alarm:*"
}

resource "aws_lambda_function" "terraform_lambda_func_certificate_expiry_dev" {
  count         = local.is-development == true ? 1 : 0
  filename      = "${path.module}/lambda_scripts/certificate_expiry_dev.zip"
  function_name = "certificate_expiry_dev"
  role          = aws_iam_role.lambda_role_certificate_expiry_dev[0].arn
  handler       = "certificate_expiry_dev.lambda_handler"
  runtime       = "python3.8"
  timeout       = 30
  reserved_concurrent_executions = 5
  depends_on    = [aws_iam_role_policy_attachment.attach_lambda_policy_certificate_expiry_to_lambda_role_certificate_expiry_dev]
   environment {
    variables = {
      EXPIRY_DAYS = "45",
	    SNS_TOPIC_ARN = "arn:aws:sns:eu-west-2:075585660276:ec2_cloudwatch_alarms"
    }
  }
#     dead_letter_config {
#    target_arn = aws_sqs_queue.lambda_queue_dev[0].arn
#  }
  tracing_config {
   mode = "Active"
  }
}

# Archive the zip file - DEV

data "archive_file" "zip_the_certificate_expiry_dev" {
  count       = local.is-development == true ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda_scripts/"
  output_path = "${path.module}/lambda_scripts/certificate_expiry_dev.zip"
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


# Lambda Function to check for Certificate Expiration - UAT

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda_certificates_expiry_uat" {
  count         = local.is-preproduction == true ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_certificate_expiry_uat[0].function_name
  principal     = "lambda.alarms.cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:172753231260:alarm:*"
}

resource "aws_lambda_function" "terraform_lambda_func_certificate_expiry_uat" {
  count         = local.is-preproduction == true ? 1 : 0
  filename      = "${path.module}/lambda_scripts/certificate_expiry_uat.zip"
  function_name = "certificate_expiry_uat"
  role          = aws_iam_role.lambda_role_certificate_expiry_uat[0].arn
  handler       = "certificate_expiry_uat.lambda_handler"
  runtime       = "python3.8"
  timeout       = 30
  reserved_concurrent_executions = 5
  depends_on    = [aws_iam_role_policy_attachment.attach_lambda_policy_certificate_expiry_to_lambda_role_certificate_expiry_uat]
   environment {
    variables = {
      EXPIRY_DAYS = "45",
	    SNS_TOPIC_ARN = "arn:aws:sns:eu-west-2:172753231260:ppud-uat-cw-alerts"
    }
  }
#    dead_letter_config {
#    target_arn = aws_sqs_queue.lambda_queue_uat[0].arn
#  }
  tracing_config {
   mode = "Active"
  }
}

# Archive the zip file - UAT

data "archive_file" "zip_the_certificate_expiry_uat" {
  count       = local.is-preproduction == true ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda_scripts/"
  output_path = "${path.module}/lambda_scripts/certificate_expiry_uat.zip"
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


# Lambda Function to check for Certificate Expiration - PROD

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda_certificates_expiry_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_certificate_expiry_prod[0].function_name
  principal     = "lambda.alarms.cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:eu-west-2:817985104434:alarm:*"
}

resource "aws_lambda_function" "terraform_lambda_func_certificate_expiry_prod" {
  count         = local.is-production == true ? 1 : 0
  filename      = "${path.module}/lambda_scripts/certificate_expiry_prod.zip"
  function_name = "certificate_expiry_prod"
  role          = aws_iam_role.lambda_role_certificate_expiry_prod[0].arn
  handler       = "certificate_expiry_prod.lambda_handler"
  runtime       = "python3.8"
  timeout       = 30
  reserved_concurrent_executions = 5
  depends_on    = [aws_iam_role_policy_attachment.attach_lambda_policy_certificate_expiry_to_lambda_role_certificate_expiry_prod]
   environment {
    variables = {
      EXPIRY_DAYS = "45",
	    SNS_TOPIC_ARN = "arn:aws:sns:eu-west-2:817985104434:ppud-prod-cw-alerts"
    }
  }
  # dead_letter_config {
  #   target_arn = aws_sqs_queue.lambda_queue_prod[0].arn
  # }
  tracing_config {
   mode = "Active"
}
}

# Archive the zip file - PROD

data "archive_file" "zip_the_certificate_expiry_prod" {
  count       = local.is-production == true ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda_scripts/"
  output_path = "${path.module}/lambda_scripts/certificate_expiry_prod.zip"
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