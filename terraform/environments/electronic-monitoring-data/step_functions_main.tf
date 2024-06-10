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

}

resource "aws_kms_key" "semantic_athena_layer_step_functions_log_key" {
  description         = "KMS key for encrypting Step Functions logs for semantic_athena_layer"
  enable_key_rotation = true

  policy = <<EOF
{
  "Id": "key-default",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${local.env_account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Enable log service Permissions",
      "Effect": "Allow",
      "Principal": {
        "Service": "logs.eu-west-2.amazonaws.com"
      },
      "Action": [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_cloudwatch_log_group" "semantic_athena_layer" {
  name              = "/aws/vendedlogs/states/semantic_athena_layer"
  retention_in_days = 400
  kms_key_id        = aws_kms_key.semantic_athena_layer_step_functions_log_key.arn
}

