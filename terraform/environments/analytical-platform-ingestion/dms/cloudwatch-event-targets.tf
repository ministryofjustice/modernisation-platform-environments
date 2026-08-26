resource "aws_cloudwatch_event_target" "tariff_metadata_generator" {
  rule      = aws_cloudwatch_event_rule.metadata_generator.name
  target_id = "tariff-metadata-generator"
  arn       = module.cica_dms_tariff_dms_implementation.metadata_generator_lambda_arn
}

resource "aws_cloudwatch_event_target" "tempus_metadata_generator" {
  for_each  = module.cica_dms_tempus_dms_implementation
  rule      = aws_cloudwatch_event_rule.metadata_generator.name
  target_id = "tempus-${each.key}-metadata-generator"
  arn       = each.value.metadata_generator_lambda_arn
}
