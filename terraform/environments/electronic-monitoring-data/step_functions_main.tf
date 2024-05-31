
resource "aws_sfn_state_machine" "semantic_athena_layer" {
  name     = "semantic-athena-layer"
  role_arn = aws_iam_role.step_functions_role.arn

  definition = <<EOF
{
  "StartAt": "GetMetadataList",
  "States": {
    "GetMetadataList": {
      "Type": "Task",
      "Resource": "${module.get_metadata_from_rds_lambda.lambda_function_arn}",
      "ResultPath": "$.metadata_list",
      "Next": "LoopThroughMetadataList"
    },
    "LoopThroughMetadataList": {
      "Type": "Map",
      "ItemsPath": "$.metadata_list.metadata_list",
      "MaxConcurrency": 4,
      "Iterator": {
        "StartAt": "CreateAthenaTable",
        "States": {
          "CreateAthenaTable": {
            "Type": "Task",
            "Resource": "${aws_lambda_function.create_athena_external_table.arn}",
            "ResultPath": "$.result",
            "End": true
          }
        }
      },
      "End": true
    }
  }
}
EOF
}
