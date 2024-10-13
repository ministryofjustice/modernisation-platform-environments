resource "aws_iam_role" "step_function_role" {
  name = "step_function_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "step_function_policy" {
  name   = "step_function_policy"
  role   = aws_iam_role.step_function_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "lambda:InvokeFunction",
        Resource = aws_lambda_function.ecs_restart_handler.arn,
      },
    ]
  })
}
resource "aws_sfn_state_machine" "ecs_restart_state_machine" {
  name     = "ecs_restart_state_machine"
  role_arn = aws_iam_role.step_function_role.arn

 definition = jsonencode({
    Comment: "State Machine to handle ECS Task Patching Retirement",
    StartAt: "CalculateWaitTimestamp",
    States: {
      CalculateWaitTimestamp: {
        Type: "Task",
        Resource: "arn:aws:lambda:${aws_lambda_function.calculate_wait_time.arn}",
        Parameters: {
          "time.$": "$.time",            # Pass the event time from the input
          "restart_time": var.restart_time
        },
        ResultPath: "$.waitTimestamp",   # Store the result in $.waitTimestamp
        Next: "WaitUntilRestartTime"
      },
      WaitUntilRestartTime: {
        Type: "Wait",
        TimestampPath: "$.waitTimestamp.timestamp",  # Use the computed timestamp
        Next: "InvokeLambdaFunction"
      },
      InvokeLambdaFunction: {
        Type: "Task",
        Resource: "arn:aws:states:::lambda:invoke",
        Parameters: {
          "FunctionName": aws_lambda_function.ecs_restart_handler.arn,
          "Payload.$": "$"
        },
        End: true
      }
    }
  })
}
