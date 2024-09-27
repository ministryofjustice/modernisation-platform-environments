# Eventbridge Rule for Certificate Expiration

resource "aws_cloudwatch_event_rule" "certificate_approaching_expiration_dev" {
  count               = local.is-development == true ? 1 : 0
  name                = "Certificate-Approaching-Expiration"
  description         = "PPUD certificate is approaching expiration"
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
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_certificate_expiry_dev[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.certificate_approaching_expiration_dev[0].arn
}