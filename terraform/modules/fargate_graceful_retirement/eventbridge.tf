resource "aws_cloudwatch_event_rule" "ecs_restart_rule" {
  name        = "ecs_task_retirement_rul"
  description = "Rule to catch AWS ECS Task Patching Retirement events"

  event_pattern = jsonencode({
    "detail-type" : ["AWS Health Event"],
    "detail" : {
      "eventTypeCode" : ["AWS_ECS_TASK_PATCHING_RETIREMENT"]
    }
  })
}

resource "aws_cloudwatch_event_target" "step_function_target" {
  rule     = aws_cloudwatch_event_rule.ecs_restart_rule.name
  arn      = aws_sfn_state_machine.ecs_restart_state_machine.arn
  role_arn = aws_iam_role.step_function_role.arn
}
