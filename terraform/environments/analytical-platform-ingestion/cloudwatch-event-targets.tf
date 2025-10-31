resource "aws_cloudwatch_event_target" "definition_update" {
  rule      = aws_cloudwatch_event_rule.definition_update.name
  target_id = "definition-update"
  arn       = module.definition_upload_lambda.lambda_function_arn
}
