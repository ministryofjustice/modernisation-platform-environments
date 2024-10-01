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
  depends_on    = [aws_iam_role_policy_attachment.attach_lambda_policy_certificate_expiry_to_lambda_role_certificate_expiry_dev]
   environment {
    variables = {
      EXPIRY_DAYS = "45",
	    SNS_TOPIC_ARN = "arn:aws:sns:eu-west-2:075585660276:ec2_cloudwatch_alarms"
    }
  }
}

# Archive the zip file

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