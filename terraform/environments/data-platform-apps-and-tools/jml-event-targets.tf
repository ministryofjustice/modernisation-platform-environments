resource "aws_cloudwatch_event_target" "jml_lambda_trigger" {
  rule      = aws_cloudwatch_event_rule.jml_lambda_trigger.name
  target_id = "jml-lambda-trigger"
  arn       = module.jml_extract.lambda_function_arn
}