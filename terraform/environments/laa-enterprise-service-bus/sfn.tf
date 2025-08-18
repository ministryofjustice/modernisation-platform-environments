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
        ResultPath = "$.GetFilesResult"
        Next = "CheckGetFilesStatus"
      },

      "CheckGetFilesStatus" = {
        Type    = "Choice"
        Choices = [
          {
            Variable      = "$.GetFilesResult.StatusCode"
            NumericEquals = 200
            Next          = "ProcessFiles"
          }
        ]
        Default = "FailState"
      },

      "FailState" = {
        Type  = "Fail"
        Error = "LambdaError"
        Cause = "GetFiles returned non-200 status or failed"
      },

      "ProcessFiles" = {
        Type          = "Map",
        ItemsPath     = "$.GetFilesResult.Payload.files",
        MaxConcurrency = 8,
        Parameters = {
          "filename.$"  = "$$.Map.Item.Value.filename",
          "timestamp.$" = "$.GetFilesResult.Payload.timestamp"
        },
        Iterator = {
          StartAt = "ProcessSingleFile",
          States = {
            "ProcessSingleFile" = {
              Type     = "Task",
              Resource = "arn:aws:states:::lambda:invoke",
              Parameters = {
                FunctionName = aws_lambda_function.cwa_file_transfer_lambda.arn
                Payload = {
                    "filename.$" = "$.filename",
                    "timestamp.$" = "$.timestamp"
                }                
              },
              ResultPath = "$.ProcessSingleFileResult"
              Next = "CheckProcessFilesStatus"
            },

            "CheckProcessFilesStatus" = {
                Type    = "Choice"
                Choices = [
                {
                    Variable      = "$.ProcessSingleFileResult.StatusCode"
                    NumericEquals = 200
                    Next          = "NextFileOrEnd"
                }
                ]
                Default = "FailSingleFile"
            },

            "FailSingleFile" = {
                Type  = "Fail"
                Error = "LambdaError"
                Cause = "File transfer failed"
            },

            "NextFileOrEnd" = {
                Type = "Pass"
                End  = true
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
