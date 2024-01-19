resource "aws_cloudwatch_event_target" "jml_lambda_trigger" {
  count = terraform.workspace == "data-platform-apps-and-tools-production" ? 1 : 0
  
  rule      = aws_cloudwatch_event_rule.jml_lambda_trigger[0].name
  target_id = "jml-lambda-trigger"
  arn       = module.jml_extract_lambda[0].lambda_function_arn
}