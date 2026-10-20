resource "aws_iam_role" "step_functions" {
  name = "${local.lambda_name}-sfn-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "states.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "step_functions_invoke_lambda" {
  name = "${local.lambda_name}-invoke-lambda"
  role = aws_iam_role.step_functions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "lambda:InvokeFunction"
      ]
      Resource = [
        aws_lambda_function.nightly_restart_lambda.arn,
        "${aws_lambda_function.nightly_restart_lambda.arn}:*"
      ]
    }]
  })
}

resource "aws_sfn_state_machine" "ecs_restart" {
  name     = "${local.lambda_name}-ecs-restart-workflow"
  role_arn = aws_iam_role.step_functions.arn
  type     = "STANDARD"

  definition = jsonencode({
    Comment        = "Disable alarm actions, restart ECS, wait for stability, then re-enable alarm actions"
    StartAt        = "Initialize"
    TimeoutSeconds = 2400

    States = {
      Initialize = {
        Type = "Pass"
        Result = {
          attempt = 0
        }
        Next = "DisableAlarms"
      }

      DisableAlarms = {
        Type     = "Task"
        Resource = "arn:${data.aws_partition.current.partition}:states:::lambda:invoke"

        Parameters = {
          FunctionName = aws_lambda_function.nightly_restart_lambda.arn
          Payload = {
            action = "disable_alarms"
          }
        }

        ResultPath = "$.disableResult"

        Retry = [{
          ErrorEquals = [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException",
            "Lambda.TooManyRequestsException"
          ]
          IntervalSeconds = 2
          MaxAttempts     = 3
          BackoffRate     = 2
        }]

        Catch = [{
          ErrorEquals = ["States.ALL"]
          ResultPath  = "$.error"
          Next        = "EnableAlarmsAfterFailure"
        }]

        Next = "StartDeployment"
      }

      StartDeployment = {
        Type     = "Task"
        Resource = "arn:${data.aws_partition.current.partition}:states:::lambda:invoke"

        Parameters = {
          FunctionName = aws_lambda_function.nightly_restart_lambda.arn
          Payload = {
            action = "start_deployment"
          }
        }

        ResultPath = "$.deploymentResult"

        Retry = [{
          ErrorEquals = [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException",
            "Lambda.TooManyRequestsException"
          ]
          IntervalSeconds = 2
          MaxAttempts     = 3
          BackoffRate     = 2
        }]

        Catch = [{
          ErrorEquals = ["States.ALL"]
          ResultPath  = "$.error"
          Next        = "EnableAlarmsAfterFailure"
        }]

        Next = "WaitBeforeCheck"
      }

      WaitBeforeCheck = {
        Type    = "Wait"
        Seconds = 15
        Next    = "CheckServiceStability"
      }

      CheckServiceStability = {
        Type     = "Task"
        Resource = "arn:${data.aws_partition.current.partition}:states:::lambda:invoke"

        Parameters = {
          FunctionName = aws_lambda_function.nightly_restart_lambda.arn
          Payload = {
            action      = "check_stability"
            "attempt.$" = "$.attempt"
          }
        }

        ResultSelector = {
          "stable.$" = "$.Payload.stable"
        }

        ResultPath = "$.checkResult"

        Retry = [{
          ErrorEquals = [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException",
            "Lambda.TooManyRequestsException"
          ]
          IntervalSeconds = 2
          MaxAttempts     = 3
          BackoffRate     = 2
        }]

        Catch = [{
          ErrorEquals = ["States.ALL"]
          ResultPath  = "$.error"
          Next        = "EnableAlarmsAfterFailure"
        }]

        Next = "IsServiceStable"
      }

      IsServiceStable = {
        Type = "Choice"

        Choices = [
          {
            Variable      = "$.checkResult.stable"
            BooleanEquals = true
            Next          = "EnableAlarms"
          },
          {
            Variable                 = "$.attempt"
            NumericGreaterThanEquals = 100
            Next                     = "DeploymentTimedOut"
          }
        ]

        Default = "IncrementAttempt"
      }

      IncrementAttempt = {
        Type = "Pass"

        Parameters = {
          "attempt.$" = "States.MathAdd($.attempt, 1)"
        }

        ResultPath = "$"
        Next       = "WaitBeforeCheck"
      }

      EnableAlarms = {
        Type     = "Task"
        Resource = "arn:${data.aws_partition.current.partition}:states:::lambda:invoke"

        Parameters = {
          FunctionName = aws_lambda_function.nightly_restart_lambda.arn
          Payload = {
            action = "enable_alarms"
          }
        }

        ResultPath = "$.enableResult"

        Retry = [{
          ErrorEquals     = ["States.ALL"]
          IntervalSeconds = 5
          MaxAttempts     = 5
          BackoffRate     = 2
        }]

        Catch = [{
          ErrorEquals = ["States.ALL"]
          ResultPath  = "$.cleanupError"
          Next        = "AlarmCleanupFailed"
        }]

        Next = "DeploymentSucceeded"
      }

      EnableAlarmsAfterFailure = {
        Type     = "Task"
        Resource = "arn:${data.aws_partition.current.partition}:states:::lambda:invoke"

        Parameters = {
          FunctionName = aws_lambda_function.nightly_restart_lambda.arn
          Payload = {
            action = "enable_alarms"
          }
        }

        Retry = [{
          ErrorEquals     = ["States.ALL"]
          IntervalSeconds = 5
          MaxAttempts     = 5
          BackoffRate     = 2
        }]

        Catch = [{
          ErrorEquals = ["States.ALL"]
          ResultPath  = "$.cleanupError"
          Next        = "AlarmCleanupFailed"
        }]

        Next = "DeploymentFailed"
      }

      DeploymentTimedOut = {
        Type = "Pass"
        Result = {
          Error = "DeploymentTimedOut"
          Cause = "ECS service did not stabilize within the polling limit"
        }
        ResultPath = "$.error"
        Next       = "EnableAlarmsAfterFailure"
      }

      DeploymentSucceeded = {
        Type = "Succeed"
      }

      DeploymentFailed = {
        Type  = "Fail"
        Error = "ECSDeploymentFailed"
        Cause = "ECS deployment failed; inspect execution history"
      }

      AlarmCleanupFailed = {
        Type  = "Fail"
        Error = "AlarmCleanupFailed"
        Cause = "Could not re-enable CloudWatch alarm actions; manual verification is required"
      }
    }
  })

  depends_on = [
    aws_iam_role_policy.step_functions_invoke_lambda
  ]
}