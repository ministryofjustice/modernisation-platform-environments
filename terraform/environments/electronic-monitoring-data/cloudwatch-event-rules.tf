resource "aws_cloudwatch_event_rule" "definition_update" {
  name                = "definition-update"
  schedule_expression = "cron(15 6 * * ? *)" # 06:15 every day
}
