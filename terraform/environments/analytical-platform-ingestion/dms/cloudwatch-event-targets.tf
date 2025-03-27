resource "aws_cloudwatch_event_target" "metadata_generator" {
  rule      = aws_cloudwatch_event_rule.metadata_generator.name
  target_id = "metadata-generator"
  arn       = module.cica_dms_tariff_dms_implementation.metadata_generator_lambda_arn
}
