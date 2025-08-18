resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "my-state-machine"
  role_arn = aws_iam_role.step_function_role.arn

  definition = jsonencode({
    Comment      = "A description of my state machine",
    StartAt      = "GetFiles",
    States = {
      "GetFiles" = {
        Type     = "Task",
        Resource = "arn:aws:states:::lambda:invoke",
        Parameters = {
          FunctionName = aws_lambda_function.cwa_extract_lambda.arn,
          Payload      = {}
        },
        Next = "ProcessFiles"
      },

      "ProcessFiles" = {
        Type          = "Map",
        ItemsPath     = "$.Payload.files",
        MaxConcurrency = 8,
        Iterator = {
          StartAt = "ProcessSingleFile",
          States = {
            "ProcessSingleFile" = {
              Type     = "Task",
              Resource = "arn:aws:states:::lambda:invoke",
              Parameters = {
                FunctionName = aws_lambda_function.cwa_file_transfer_lambda.arn
                Payload = {
                    "filename.$" = "$.filename"
                    "timestamp.$" = "$.Payload.timestamp"
                }                
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
        Parameters = {
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
