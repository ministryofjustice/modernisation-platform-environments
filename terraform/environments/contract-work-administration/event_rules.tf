resource "aws_cloudwatch_event_rule" "create_db_snapshots" {

  name                = "${local.application_name_short}-${local.environment}-create-db-snapshots"
  description         = "Daily snapshots of Oracle volumes"
  schedule_expression = "cron(0 2 ? * MON-SUN *)"
  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-create-db-snapshots" }
  )

}

resource "aws_lambda_permission" "create_db_snapshots" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_db_snapshots.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.create_db_snapshots.arn
}

resource "aws_cloudwatch_event_target" "create_db_snapshots" {
  rule  = aws_cloudwatch_event_rule.create_db_snapshots.name
  arn   = aws_lambda_function.create_db_snapshots.arn
  input = jsonencode({ "appname" : "${local.database_ec2_name}" })
}

resource "aws_cloudwatch_event_rule" "delete_db_snapshots" {
  name                = "${local.application_name_short}-${local.environment}-delete-db-snapshots"
  description         = "Delete snapshots over 35 days old"
  schedule_expression = "cron(10 2 ? * MON-FRI *)"

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-delete-db-snapshots" }
  )
}

resource "aws_lambda_permission" "delete_db_snapshots" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete_db_snapshots.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.delete_db_snapshots.arn
}

resource "aws_cloudwatch_event_target" "delete_db_snapshots" {
  rule = aws_cloudwatch_event_rule.delete_db_snapshots.name
  arn  = aws_lambda_function.delete_db_snapshots.arn
}
