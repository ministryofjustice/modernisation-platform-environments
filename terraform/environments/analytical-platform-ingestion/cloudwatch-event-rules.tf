resource "aws_cloudwatch_event_rule" "ingestion_scanning_definition_update" {
  name                = "ingestion-scanning-definition-update"
  schedule_expression = "cron(15 6 * * ? *)" # 06:15 every day
}
