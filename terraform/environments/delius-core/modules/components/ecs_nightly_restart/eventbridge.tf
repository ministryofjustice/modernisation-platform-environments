resource "aws_iam_role" "eventbridge_step_functions" {
  name = "${local.lambda_name}-eventbridge-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_cloudwatch_event_rule" "rule" {
  name                = "${local.lambda_name}-rule"
  schedule_expression = local.schedule_expression
}

resource "aws_cloudwatch_event_target" "target" {
  rule     = aws_cloudwatch_event_rule.rule.name
  arn      = aws_sfn_state_machine.ecs_restart.arn
  role_arn = aws_iam_role.eventbridge_step_functions.arn
}