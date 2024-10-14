resource "aws_cloudwatch_event_rule" "ecs_restart_rule" {
  name        = "ecs_task_retirement_rule"
  description = "Rule to catch AWS ECS Task Patching Retirement events"
  event_pattern = jsonencode({
    "source" : ["aws.health"],
    "detail-type" : ["AWS Health Event"],
    "detail" : {
      "eventTypeCode" : ["AWS_ECS_TASK_PATCHING_RETIREMENT"]
    }
  })
}

# resource "aws_cloudwatch_event_target" "ecs_restarts_target" {
#   rule = aws_cloudwatch_event_rule.ecs_restart_rule.name
#   arn  = aws_lambda_function.ecs_restart_handler.arn
# }

resource "aws_cloudwatch_event_target" "step_function_target" {
  rule = aws_cloudwatch_event_rule.ecs_restart_rule.name
  arn  = aws_sfn_state_machine.ecs_restart_state_machine.arn
}
