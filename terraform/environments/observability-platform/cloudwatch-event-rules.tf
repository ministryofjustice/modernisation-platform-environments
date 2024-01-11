resource "aws_cloudwatch_event_rule" "grafana_api_key_rotator" {
  name                = "grafana-api-key-rotator"
  schedule_expression = "cron(0 2 ? * MON *)"
}
