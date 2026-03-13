#-----------------------------------------------------------------------------------
# Schedule MDSS reconciler (every 5 minutes)
#-----------------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "mdss_reconciler_schedule" {
  count               = local.is-preproduction || local.is-production ? 0 : 1
  name                = "mdss_reconciler_schedule"
  description         = "Runs mdss_reconciler on a schedule to backstop missed MDSS loads"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "mdss_reconciler_target" {
  count = local.is-preproduction || local.is-production ? 0 : 1
  rule  = aws_cloudwatch_event_rule.mdss_reconciler_schedule[0].name
  arn   = module.mdss_reconciler[0].lambda_function_arn
}

resource "aws_lambda_permission" "mdss_reconciler_allow_eventbridge" {
  count         = local.is-preproduction || local.is-production ? 0 : 1
  statement_id  = "AllowExecutionFromEventBridgeMdssReconciler"
  action        = "lambda:InvokeFunction"
  function_name = module.mdss_reconciler[0].lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.mdss_reconciler_schedule[0].arn
}