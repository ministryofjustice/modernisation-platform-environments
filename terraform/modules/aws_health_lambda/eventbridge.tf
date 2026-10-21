resource "aws_cloudwatch_event_rule" "aws_health" {
  name        = "${var.project_name}-aws-health-lambda-rule"
  description = "Send AWS Health events to the ${var.project_name} Lambda"

  event_pattern = jsonencode({
    source        = ["aws.health"]
    "detail-type" = ["AWS Health Event"]
  })
}

resource "aws_cloudwatch_event_target" "aws_health" {
  rule      = aws_cloudwatch_event_rule.aws_health.name
  target_id = "${var.project_name}-target"
  arn       = aws_lambda_function.github_workflow_trigger.arn

  depends_on = [aws_lambda_permission.aws_health]
}

resource "aws_lambda_permission" "aws_health" {
  statement_id   = "AllowAWSHealthEventBridge"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.github_workflow_trigger.function_name
  principal      = "events.amazonaws.com"
  source_arn     = aws_cloudwatch_event_rule.aws_health.arn
  source_account = var.aws_account_id
}

resource "aws_lambda_permission" "allow_external_aws_accounts_eventbridge" {
  for_each = nonsensitive(toset(keys(local.aws_accounts)))

  statement_id  = "AllowHealthEvents${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.github_workflow_trigger.function_name
  principal     = "events.amazonaws.com"

  source_arn = "arn:aws:events:${var.aws_region}:${local.aws_accounts[each.key]}:rule/ForwardAllHealthEvents"
}
