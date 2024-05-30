
resource "aws_sfn_state_machine" "semantic_athena_layer" {
  name     = "semantic-athena-layer"
  role_arn = aws_iam_role.step_functions_role

  definition = <<EOF
{
  "StartAt": "GetMetadataList",
  "States": {
    "GetMetadataList": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.get_metadata_from_rds.arn}",
      "ResultPath": "$.metadata_list",
      "Next": "LoopThroughMetadataList"
    },
    "LoopThroughMetadataList": {
      "Type": "Map",
      "ItemsPath": "$.metadata_list",
      "MaxConcurrency": 4, 
      "Iterator": {
        "StartAt": "CreateGlueTable",
        "States": {
        "CreateAthenaTable": {
            "Type": "Task",
            "Resource": "arn:aws:states:::lambda:invoke",
            "Parameters": {
                "FunctionName": "${aws_lambda_function.create_athena_external_table.arn}",
                "Payload": {
                    "ExecutionContext.$": "$$",
                    "table_meta": "$"
                }
            },
            "End": true
        },
      },
      "End": true
    }
  }
}
EOF
}
