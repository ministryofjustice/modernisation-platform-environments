################################################
# Eventbridge Rules (to invoke Lambda functions)
################################################

# Eventbridge rule to invoke the Send CPU Graph lambda function every weekday at 17:05

resource "aws_lambda_permission" "allow_eventbridge_invoke_send_cpu_graph_prod" {
  count         = local.is-production == true ? 1 : 0
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func_send_cpu_graph_prod[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_schedule_send_cpu_graph_prod[0].arn
}

resource "aws_cloudwatch_event_rule" "daily_schedule_send_cpu_graph_prod" {
  count               = local.is-production == true ? 1 : 0
  name                = "send-cpu-graph-daily-weekday-schedule"
  description         = "Trigger Lambda at 17:00 UTC on weekdays"
  schedule_expression = "cron(5 17 ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda_target_send_cpu_graph_prod" {
 count      = local.is-production == true ? 1 : 0
  rule      = aws_cloudwatch_event_rule.daily_schedule_send_cpu_graph_prod[0].name
  target_id = "send_cpu_graph"
  arn       = aws_lambda_function.terraform_lambda_func_send_cpu_graph_prod[0].arn
}
