resource "aws_sfn_state_machine" "athena_layer" {
  name     = "athena-layer"
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
            "Resource": "${module.create_athena_table.lambda_function_arn}",
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

resource "aws_kms_key" "athena_layer_step_functions_log_key" {
  description = "KMS key for encrypting Step Functions logs for athena_layer"
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

resource "aws_cloudwatch_log_group" "athena_layer" {
  name = "/aws/vendedlogs/states/athena_layer"
  retention_in_days = 400
  kms_key_id = aws_kms_key.athena_layer_step_functions_log_key.arn
}
# ------------------------------------------
# Send Database to AP
# ------------------------------------------

resource "aws_sfn_state_machine" "send_database_to_ap" {
  name     = "send_database_to_ap_layer"
  role_arn = aws_iam_role.send_database_to_ap.arn

  definition = <<EOF
{
  "StartAt": "GetMetadataList",
  "States": {
    "GetMetadataList": {
      "Type": "Task",
      "Resource": "${module.get_tables_from_db.lambda_function_arn}",
      "ResultPath": "$.db_info",
      "Next": "LoopThroughMetadataList"
    },
    "LoopThroughMetadataList": {
      "Type": "Map",
      "ItemsPath": "$.db_info",
      "MaxConcurrency": 4,
      "Iterator": {
        "StartAt": "GetTableFileNames",
        "States": {
          "GetTableFileNames": {
            "Type": "Task",
            "Resource": "${module.get_file_keys_for_table.lambda_function_arn}",
            "ResultPath": "$.result",
            "Next": "LoopThroughFileKeys"
          },
          "LoopThroughFileKeys": {
          "Type": "Map",
          "ItemsPath": "$.result",
          "MaxConcurrency": 4,
          "Iterator": {
            "StartAt": "SendTableToAp",
            "States": {
              "SendTableToAp": {
                "Type": "Task",
                "Resource": "${module.send_table_to_ap.lambda_function_arn}",
                "ResultPath": "$.final_result",
                "End": true
                }
              }
            },
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

resource "aws_kms_key" "send_database_to_ap_step_functions_log_key" {
  description = "KMS key for encrypting Step Functions logs for send_database_to_ap"
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

resource "aws_cloudwatch_log_group" "send_database_to_ap" {
  name = "/aws/vendedlogs/states/send_database_to_ap"
  retention_in_days = 400
  kms_key_id = aws_kms_key.send_database_to_ap_step_functions_log_key.arn
}
