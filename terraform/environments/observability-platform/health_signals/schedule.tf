resource "aws_cloudwatch_event_rule" "health_signals_schedule" {
  name                = "${var.name_prefix}-health-signals-schedule"
  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "health_signals_target" {
  rule      = aws_cloudwatch_event_rule.health_signals_schedule.name
  target_id = "health-signals"
  arn       = aws_lambda_function.health_signals.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.health_signals.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.health_signals_schedule.arn
}
