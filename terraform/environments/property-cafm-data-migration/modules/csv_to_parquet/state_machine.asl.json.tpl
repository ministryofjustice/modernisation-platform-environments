{
  "Comment": "CSV to Parquet Export (classic ASL)",
  "StartAt": "InvokeLambda",
  "States": {
    "InvokeLambda": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "Parameters": {
        "FunctionName": "${lambda_arn}",
        "Payload.$": "$"
      },
      "OutputPath": "$.Payload",
      "End": true
    }
  }
}
