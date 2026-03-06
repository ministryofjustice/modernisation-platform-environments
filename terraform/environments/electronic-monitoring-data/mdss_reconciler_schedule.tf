#-----------------------------------------------------------------------------------
# Schedule MDSS reconciler (every 5 minutes)
#-----------------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "mdss_reconciler_schedule" {
  name                = "mdss_reconciler_schedule"
  description         = "Runs mdss_reconciler on a schedule to backstop missed MDSS loads"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "mdss_reconciler_target" {
  rule = aws_cloudwatch_event_rule.mdss_reconciler_schedule.name
  arn  = module.mdss_reconciler.lambda_function_arn
}

resource "aws_lambda_permission" "mdss_reconciler_allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridgeMdssReconciler"
  action        = "lambda:InvokeFunction"
  function_name = module.mdss_reconciler.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.mdss_reconciler_schedule.arn
}