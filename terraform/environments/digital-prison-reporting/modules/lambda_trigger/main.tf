resource "aws_cloudwatch_event_rule" "event_rule" {
  count = var.enable_lambda_trigger ? 1 : 0

  name                = "${var.event_name}-event-rule"
  schedule_expression = var.trigger_schedule_expression
  event_pattern       = var.trigger_event_pattern
  event_bus_name      = var.event_bus_name

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "event_target" {
  count = var.enable_lambda_trigger ? 1 : 0

  rule           = aws_cloudwatch_event_rule.event_rule[0].name
  target_id      = "${aws_cloudwatch_event_rule.event_rule[0].name}-target"
  arn            = var.lambda_function_arn
  input          = var.trigger_input_event
  event_bus_name = var.event_bus_name
}

resource "aws_lambda_permission" "cloudwatch_lambda_trigger_permission" {
  count = var.enable_lambda_trigger ? 1 : 0

  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.event_rule[0].arn
}