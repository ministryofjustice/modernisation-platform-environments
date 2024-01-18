resource "aws_cloudwatch_event_rule" "jml_lambda_trigger" {
  name                = "jml-lambda-trigger-rules"
  schedule_expression = "cron(0 2 1 * ? *)"
}