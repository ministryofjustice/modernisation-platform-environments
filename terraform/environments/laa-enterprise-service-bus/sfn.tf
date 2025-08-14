resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "my-state-machine"
  role_arn = aws_iam_role.step_function_role.arn

  definition = jsonencode({
    Comment      = "A description of my state machine",
    StartAt      = "Lambda Invoke",
    QueryLanguage = "JSONata",
    States = {
      "Lambda Invoke" = {
        Type     = "Task",
        Resource = "arn:aws:states:::lambda:invoke",
        Output   = "{% $states.result.Payload %}",
        Arguments = {
          FunctionName = aws_lambda_function.cwa_test_1.arn,
          Payload      = "{% $states.input %}"
        },
        Retry = [{
          ErrorEquals     = ["Lambda.TooManyRequestsException"],
          IntervalSeconds = 2,
          MaxAttempts     = 2
        }],
        Next = "Parallel"
      },

      Parallel = {
        Type     = "Parallel",
        Branches = [
          {
            StartAt = "Lambda Invoke (1)",
            States  = {
              "Lambda Invoke (1)" = {
                Type     = "Task",
                Resource = "arn:aws:states:::lambda:invoke",
                Output   = "{% $states.result.Payload %}",
                Arguments = {
                  FunctionName = aws_lambda_function.cwa_test_2.arn,
                  Payload      = "{% $states.input %}"
                },
                Retry = [{
                  ErrorEquals     = [
                    "Lambda.ServiceException",
                    "Lambda.AWSLambdaException",
                    "Lambda.SdkClientException",
                    "Lambda.TooManyRequestsException"
                  ],
                  IntervalSeconds = 1,
                  MaxAttempts     = 3,
                  BackoffRate     = 2,
                  JitterStrategy  = "FULL"
                }],
                End = true
              }
            }
          },
          {
            StartAt = "Lambda Invoke (2)",
            States  = {
              "Lambda Invoke (2)" = {
                Type     = "Task",
                Resource = "arn:aws:states:::lambda:invoke",
                Output   = "{% $states.result.Payload %}",
                Arguments = {
                  FunctionName = aws_lambda_function.cwa_test_3.arn,
                  Payload      = "{% $states.input %}"
                },
                Retry = [{
                  ErrorEquals     = ["Lambda.TooManyRequestsException"],
                  IntervalSeconds = 2,
                  MaxAttempts     = 2
                }],
                End = true
              }
            }
          }
        ],
        Next = "Lambda Invoke (3)"
      },

      "Lambda Invoke (3)" = {
        Type     = "Task",
        Resource = "arn:aws:states:::lambda:invoke",
        Output   = "{% $states.result.Payload %}",
        Arguments = {
          FunctionName = aws_lambda_function.cwa_test_4.arn,
          Payload      = "{% $states.input %}"
        },
        Retry = [{
          ErrorEquals     = ["Lambda.TooManyRequestsException"],
          IntervalSeconds = 2,
          MaxAttempts     = 2
        }],
        End = true
      }
    }
  })
}
