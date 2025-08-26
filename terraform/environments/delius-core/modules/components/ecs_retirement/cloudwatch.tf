resource "aws_cloudwatch_event_rule" "ecs_task_retirement" {
  name        = "EcsTaskRetirementEventRule"
  description = "Triggers Lambda on AWS ECS task retirement health events"

  event_pattern = jsonencode({
    "detail-type" : ["AWS Health Event"],
    "detail" : {
      "eventTypeCode" : ["AWS_ECS_TASK_PATCHING_RETIREMENT"]
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.ecs_task_retirement.name
  target_id = "TaskRetirementLambdaTarget"
  arn       = aws_lambda_function.task_retirement_lambda.arn
}

resource "aws_lambda_permission" "allow_eventbridge_invoke" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.task_retirement_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ecs_task_retirement.arn
}