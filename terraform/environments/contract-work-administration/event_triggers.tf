resource "aws_cloudwatch_event_rule" "deletesnapshotFunction_mon_fri" {
  name                = "laa-deletesnapshotRule-${local.application_name_short}-${local.environment}-mp"
  description         = "Delete snapshots over 35 days old"
  schedule_expression = "cron(10 02 ? * MON-FRI *)"

  tags = merge(
    local.tags,
    { Name = "laa-deletesnapshotRule-${local.application_name_short}-${local.environment}-mp" }
  )
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_check_mon_fri" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete_db_snapshots.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.deletesnapshotFunction_mon_fri.arn
}

resource "aws_cloudwatch_event_target" "deletesnapshotFunctioncheck_mon_fri" {
  rule = aws_cloudwatch_event_rule.deletesnapshotFunction_mon_fri.name
  arn  = aws_lambda_function.delete_db_snapshots.arn
}