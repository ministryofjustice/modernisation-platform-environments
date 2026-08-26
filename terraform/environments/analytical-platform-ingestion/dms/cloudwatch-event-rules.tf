resource "aws_cloudwatch_event_rule" "metadata_generator" {
  name                = "metadata-generator"
  schedule_expression = "cron(0 0 * * ? *)" # midnight every day
}
