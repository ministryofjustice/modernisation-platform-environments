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
            "Resource": "${module.create_athena_external_table.lambda_function_arn}",
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

  tracing_configuration {
    enabled = true
  }

  logging_configuration {
    level = "ALL"
    include_execution_data = true
    log_destination        = "${aws_cloudwatch_log_group.semantic_athena_layer.arn}:*"
  }
}

resource "aws_cloudwatch_log_group" "semantic_athena_layer" {
  name = "/aws/step-functions/semantic_athena_layer"
}