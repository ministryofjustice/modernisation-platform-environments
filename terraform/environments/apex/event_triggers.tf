resource "aws_cloudwatch_event_rule" "snapshotDBFunctionmon_sun" {
    name = "laa-createSnapshotRule-${local.application_name}-${local.environment}-mp"
    description = "Daily snapshots of Oracle volumes"
    schedule_expression = "cron(25 16 ? * MON-SUN *)"
}
resource "aws_lambda_permission" "allow_cloudwatch_to_call_check_mon_sun" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.snapshotDBFunction.function_name
    principal = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.snapshotDBFunctionmon_sun.arn
}

resource "aws_cloudwatch_event_target" "snapshotDBFunctioncheck_mon_sun" {
    rule = aws_cloudwatch_event_rule.snapshotDBFunctionmon_sun.name
    arn = aws_lambda_function.snapshotDBFunction.arn
    input =jsonencode({"appname": "apex Database Server"})
}




resource "aws_cloudwatch_event_rule" "deletesnapshotFunction_mon_fri" {
    name = "laa-deletesnapshotRule-${local.application_name}-${local.environment}-mp"
    description = "Delete snapshots over 35 days old"
    schedule_expression = "cron(10 02 ? * MON-FRI *)"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_check_mon_fri" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.deletesnapshotFunction.function_name
    principal = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.deletesnapshotFunction_mon_fri.arn
}

resource "aws_cloudwatch_event_target" "deletesnapshotFunctioncheck_mon_fri" {
    rule = aws_cloudwatch_event_rule.deletesnapshotFunction_mon_fri.name
    arn = aws_lambda_function.deletesnapshotFunction.arn
    input =jsonencode({"appname": "apex Database Server"})
}

