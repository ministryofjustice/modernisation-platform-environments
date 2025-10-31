resource "aws_iam_role" "step_function_role" {
  name = "${var.environment}_step_function_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "step_function_policy" {
  name = "${var.environment}_step_function_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "lambda:InvokeFunction",
        Resource = [aws_lambda_function.ecs_restart_handler.arn, aws_lambda_function.calculate_wait_time.arn]
      },
      {
        Effect   = "Allow"
        Action   = "logs:*",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "step_function_policy_attachment" {
  policy_arn = aws_iam_policy.step_function_policy.arn
  role       = aws_iam_role.step_function_role.name
}

resource "aws_cloudwatch_log_group" "log_group_for_sfn" {
  name = "/aws/states/ecs_restart_state_machine/${var.environment}"
}

resource "aws_sfn_state_machine" "ecs_restart_state_machine" {
  name     = "${var.environment}_ecs_restart_state_machine"
  role_arn = aws_iam_role.step_function_role.arn

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.log_group_for_sfn.arn}:*"
    include_execution_data = var.debug_logging ? true : false
    level                  = var.debug_logging ? "ALL" : "ERROR"
  }

  definition = jsonencode({
    Comment : "State Machine to handle ECS Task Patching Retirement",
    StartAt : "CalculateWaitTimestamp",
    States : {
      CalculateWaitTimestamp : {
        Type : "Task",
        Resource : aws_lambda_function.calculate_wait_time.arn,
        Parameters : {
          "time.$" : "$.time", # Pass the event time from the input
          "restart_time" : var.restart_time
          "restart_day_of_the_week" : var.restart_day_of_the_week
        },
        ResultPath : "$.waitTimestamp", # Store the result in $.waitTimestamp
        Next : "WaitUntilRestartTime"
      },
      WaitUntilRestartTime : {
        Type : "Wait",
        TimestampPath : "$.waitTimestamp.timestamp", # Use the computed timestamp
        Next : "CheckIfLDAPExists"
      },
      # Choice state to branch if LDAP services exist
      CheckIfLDAPExists : {
        Type : "Choice",
        Choices : [
          {
            Variable : "$.detail.affectedEntities[0].entityValue",
            StringMatches : "*-ldap",
            Next : "OpenCircuitBreaker"
          }
        ],
        Default : "RestartECSService"
      },
      OpenCircuitBreaker : {
        Type : "Task",
        Resource : "arn:aws:states:::lambda:invoke",
        Parameters : {
          "FunctionName" : aws_lambda_function.ldap_circuit_handler.arn,
          "Payload" : {
            "action" : "open"
          }
        },
        Next : "RestartECSService"
      },
      RestartECSService : {
        Type : "Task",
        Resource : "arn:aws:states:::lambda:invoke",
        Parameters : {
          "FunctionName" : aws_lambda_function.ecs_restart_handler.arn,
          "Payload.$" : "$"
        },
        ResultPath : "$.restartECSResult",
        Next : "PostRestartChoice"
      },
      # After restart, check again: if LDAP then wait for targets + close circuit breaker
      # else just end the steps
      PostRestartChoice : {
        Type : "Choice",
        Choices = [
          {
            Variable : "$.ldapServices[0]",
            IsPresent : true,
            Next : "WaitForTargetsHealthy"
          }
        ],
        Default : "EndStep"
      },

      WaitForTargetsHealthy : {
        Type : "Task",
        Resource : "arn:aws:states:::lambda:invoke",
        Parameters : {
          "FunctionName" : aws_lambda_function.ldap_circuit_handler.arn,
          "Payload" : {
            "action" : "check_health"
          }
        },
        Retry : [
          {
            ErrorEquals : ["TargetsNotReady"],
            IntervalSeconds : 20,
            BackoffRate : 1.2,
            MaxAttempts : 30
          }
        ],
        Next : "CloseCircuitBreaker"
      },
      # finally close circuit breaker
      CloseCircuitBreaker : {
        Type : "Task",
        Resource : "arn:aws:states:::lambda:invoke",
        Parameters : {
          "FunctionName" : aws_lambda_function.ldap_circuit_handler.arn,
          "Payload" : {
            "action" : "close"
          }
        },
        Next : "EndStep"
      },
      EndStep : {
        Type : "Succeed"
      }
    }
  })
}
