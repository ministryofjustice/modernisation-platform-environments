resource "aws_cloudwatch_event_rule" "jml_lambda_trigger" {
  count = terraform.workspace == "data-platform-apps-and-tools-production" ? 1 : 0

  name                = "jml-lambda-trigger"
  schedule_expression = "cron(0 2 1 * ? *)"
}
