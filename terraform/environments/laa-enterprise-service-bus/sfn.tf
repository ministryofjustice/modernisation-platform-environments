resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "my-state-machine"
  role_arn = aws_iam_role.step_function_role.arn

  definition = jsonencode({
    Comment      = "A description of my state machine",
    StartAt      = "Lambda Invoke",
    QueryLanguage = "JSONata",
    States = {
      "Lambda1" = {
        Type     = "Task",
        Resource = "arn:aws:states:::lambda:invoke",
        Output   = "{% $states.result.Payload %}",
        Arguments = {
          FunctionName = aws_lambda_function.cwa_test_1.arn,
          Payload      = "{% $states.input %}"
        },
        ResultPath = "$.lambda1Result"
        Next = "MapState"
      },

      "MapState" = {
        Type          = "Map"
        ItemsPath     = "$.lambdaAResult.jobs"
        MaxConcurrency = 8
        Iterator = {
          StartAt = "Lambda2"
          States = {
            "Lambda2" = {
              Type     = "Task"
              Resource = "arn:aws:states:::lambda:invoke"
              Parameters = {
                FunctionName = aws_lambda_function.cwa_test_2.arn
                Payload      = "{% $states.input %}"
              }
              End = true
            }
          }
        }
        Next = "Lambda3"
      }

      "Lambda3" = {
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
  })
}
