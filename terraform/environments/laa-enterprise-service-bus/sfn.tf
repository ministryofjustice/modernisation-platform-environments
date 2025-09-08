resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "cwa-step-function"
  role_arn = aws_iam_role.step_function_role.arn

  definition = jsonencode({
    Comment = "A description of my state machine",
    StartAt = "GetFiles",
    States = {
      "GetFiles" = {
        Type     = "Task",
        Resource = "arn:aws:states:::lambda:invoke",
        Parameters = {
          FunctionName = aws_lambda_function.cwa_extract_lambda.arn,
          Payload      = {}
        },
        ResultPath = "$.GetFilesResult"
        Next       = "CheckGetFilesStatus"
      },

      "CheckGetFilesStatus" = {
        Type = "Choice"
        Choices = [
          {
            Variable      = "$.GetFilesResult.Payload.statusCode"
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
        Type           = "Map",
        ItemsPath      = "$.GetFilesResult.Payload.body.files",
        MaxConcurrency = 8,
        Parameters = {
          "filename.$"  = "$$.Map.Item.Value.filename",
          "timestamp.$" = "$.GetFilesResult.Payload.body.timestamp"
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
                  "filename.$"  = "$.filename",
                  "timestamp.$" = "$.timestamp"
                }
              },
              ResultPath = "$.ProcessSingleFileResult"
              Next       = "CheckProcessFilesStatus"
            },

            "CheckProcessFilesStatus" = {
              Type = "Choice"
              Choices = [
                {
                  Variable      = "$.ProcessSingleFileResult.Payload.statusCode"
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
        ResultPath = "$.ProcessedFiles",
        Next       = "WrapMapOutput"
      },

      "WrapMapOutput" = {
        Type = "Pass",
        Parameters = {
          "results.$" = "$.ProcessedFiles"
        },
        ResultPath = "$.WrappedResults",
        Next       = "PublishToSNS"
      },

      "PublishToSNS" = {
        Type     = "Task",
        Resource = "arn:aws:states:::lambda:invoke",
        Parameters = {
          FunctionName = aws_lambda_function.cwa_sns_lambda.arn,
          Payload = {
            "timestamp.$" = "$.WrappedResults.results[0].timestamp"
          }
        },
        ResultPath = "$.PublishToSNSResult",
        Next       = "CheckPublishToSNSStatus"
      },
      "CheckPublishToSNSStatus" = {
        Type = "Choice",
        Choices = [
          {
            Variable      = "$.PublishToSNSResult.Payload.statusCode",
            NumericEquals = 200,
            Next          = "SuccessState"
          }
        ],
        Default = "FailSNS"
      },

      "FailSNS" = {
        Type  = "Fail",
        Error = "LambdaError",
        Cause = "PublishToSNS returned non-200 status or failed"
      },

      "SuccessState" = {
        Type = "Succeed"
      }
    }
  })

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-cwa-step-function"
    }
  )
}
