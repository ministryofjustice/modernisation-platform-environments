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

resource "aws_iam_role_policy" "eventbridge_start_execution" {
  name = "${local.lambda_name}-start-sfn-execution"
  role = aws_iam_role.eventbridge_step_functions.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Action = [
        "states:StartExecution"
      ]

      Resource = aws_sfn_state_machine.ecs_restart.arn
    }]
  })
}

resource "aws_scheduler_schedule" "nightly_restart" {
  name        = "${local.lambda_name}-nightly-restart"

  schedule_expression          = local.schedule_expression
  schedule_expression_timezone = "Europe/London"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_sfn_state_machine.ecs_restart.arn
    role_arn = aws_iam_role.eventbridge_step_functions.arn
  }

  depends_on = [
    aws_iam_role_policy.eventbridge_start_execution
  ]
}