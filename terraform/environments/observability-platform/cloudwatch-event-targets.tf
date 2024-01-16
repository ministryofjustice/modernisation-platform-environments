resource "aws_cloudwatch_event_target" "grafana_api_key_rotator" {
  rule      = aws_cloudwatch_event_rule.grafana_api_key_rotator.name
  target_id = "grafana-api-key-rotator"
  arn       = module.grafana_api_key_rotator.lambda_function_arn
}
