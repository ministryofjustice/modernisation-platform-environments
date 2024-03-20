resource "aws_cloudwatch_event_target" "ingestion_scanning_definition_update" {
  rule      = aws_cloudwatch_event_rule.ingestion_scanning_definition_update.name
  target_id = "ingestion_scanning_definition_update"
  arn       = module.definition_upload_lambda.lambda_function_arn
}
