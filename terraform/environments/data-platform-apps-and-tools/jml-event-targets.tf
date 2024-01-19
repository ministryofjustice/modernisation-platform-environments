resource "aws_cloudwatch_event_target" "jml_lambda_trigger" {
  rule      = aws_cloudwatch_event_rule.jml_lambda_trigger.name
  target_id = "jml-lambda-trigger"
  arn       = module.lambda_function_from_container_image.lambda_function_arn
}