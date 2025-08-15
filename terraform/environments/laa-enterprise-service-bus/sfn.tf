resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "my-state-machine"
  role_arn = aws_iam_role.step_function_role.arn

  definition = jsonencode({
    Comment      = "A description of my state machine",
    StartAt      = "GetFiles",
    QueryLanguage = "JSONata",
    States = {
      "GetFiles" = {
        Type     = "Task",
        Resource = "arn:aws:states:::lambda:invoke",
        Arguments = {
          FunctionName = aws_lambda_function.cwa_extract_lambda_new.arn,
          Payload      = "$"
        },
        Next = "ProcessFiles"
      },

      "ProcessFiles" = {
        Type          = "Map",
        ItemsPath     = "$.files",
        MaxConcurrency = 8,
        Iterator = {
          StartAt = "ProcessFiles",
          States = {
            "ProcessFiles" = {
              Type     = "Task",
              Resource = "arn:aws:states:::lambda:invoke",
              Parameters = {
                FunctionName = aws_lambda_function.cwa_file_transfer_lambda.arn
                "filename.$" = "$.filename"
              },
              End = true
            }
          }
        }
        Next = "PublishToSNS"
      },

      "PublishToSNS" = {
        Type     = "Task",
        Resource = "arn:aws:states:::lambda:invoke",
        Arguments = {
          FunctionName = aws_lambda_function.cwa_sns_lambda.arn,
          Payload      = "$"
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
